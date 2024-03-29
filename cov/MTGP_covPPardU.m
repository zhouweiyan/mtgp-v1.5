function K = MTGP_covPPardU(v, hyp, x, z, i)

% Piecewise polynomial covariance function with compact support, v = 0,1,2,3.
% The covariance functions are 2v times contin. diff'ble and the corresponding
% processes are hence v times  mean-square diffble. The covariance function is:
%
% k(x^p,x^q) = s2f * max(1-r,0)^(j+v) * f(r,j) with j = floor(D/2)+v+1
%
% where r is the distance sqrt((x^p-x^q)'*inv(P)*(x^p-x^q)), and the P matrix
% is diagonal with ARD parameters ell_1^2,...,ell_D^2, where D is the dimension
% of the input space and sf2 is the signal variance. The hyperparameters are:
%
% hyp = [ log(ell_1)
%         log(ell_2)
%          ..
%         log(ell_D)]
%
% Copyright (c) by Carl Edward Rasmussen and Hannes Nickisch, 2013-10-14.
%
% See also COVFUNCTIONS.M.

if nargin<3, K = 'D-1'; return; end              % report number of parameters
if nargin<4, z = []; end                                   % make sure, z exists
xeqz = numel(z)==0; dg = strcmp(z,'diag') && numel(z)>0;        % determine mode

n = size(x,1); D = size(x,2)-1;
ell = exp(hyp(1:D));
if all(v~=[0,1,2,3]), error('only 0,1,2 and 3 allowed for v'), end      % degree

j = floor(D/2)+v+1;                                                   % exponent

switch v
  case 0,  f = @(r,j) 1;
          df = @(r,j) 0;
  case 1,  f = @(r,j) 1 + (j+1)*r;
          df = @(r,j)     (j+1);
  case 2,  f = @(r,j) 1 + (j+2)*r +   (  j^2+ 4*j+ 3)/ 3*r.^2;
          df = @(r,j)     (j+2)   + 2*(  j^2+ 4*j+ 3)/ 3*r;
  case 3,  f = @(r,j) 1 + (j+3)*r +   (6*j^2+36*j+45)/15*r.^2 ...
                                + (j^3+9*j^2+23*j+15)/15*r.^3;
          df = @(r,j)     (j+3)   + 2*(6*j^2+36*j+45)/15*r    ...
                                + (j^3+9*j^2+23*j+15)/ 5*r.^2;
end
 pp = @(r,j,v,f) max(1-r,0).^(j+v).*f(r,j);
dpp = @(r,j,v,f) max(1-r,0).^(j+v-1).*r.*( (j+v)*f(r,j) - max(1-r,0).*df(r,j) );

% precompute squared distances
if dg                                                               % vector kxx
  K = zeros(size(x,1),1);
else
  if xeqz                                                 % symmetric matrix Kxx
    K = sqrt( sq_dist(diag(1./ell)*x(:,1:end-1)') );
  else                                                   % cross covariances Kxz
    K = sqrt( sq_dist(diag(1./ell)*x(:,1:end-1)',diag(1./ell)*z(:,1:end-1)') );
  end
end

if nargin<5                                                        % covariances
  K = pp( K, j, v, f );
else                                                               % derivatives
  if i<=D                                               % length scale parameter
    if dg
      Ki = zeros(size(x,1),1);
    else
      if xeqz
        Ki = sq_dist(1/ell(i)*x(:,i)');
      else
        Ki = sq_dist(1/ell(i)*x(:,i)',1/ell(i)*z(:,i)');
      end
    end
    K = dpp( K, j, v, f ).*Ki./K.^2;
    K(Ki<1e-12) = 0;                                            % fix limit case
  elseif i==D+1                                            % magnitude parameter
    K = 2*pp( K, j, v, f );
  else
    error('Unknown hyperparameter')
  end
end
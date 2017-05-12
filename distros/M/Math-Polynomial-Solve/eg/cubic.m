function  [x] = cubic (a,b,c,d)

% [x] = cubic (a,b,c,d)
%
%   Gives the roots of the cubic equation
%         ax^3 + bx^2 + cx + d = 0    (a <> 0 !!)
%   by Nickalls's method: R. W. D. Nickalls, ``A New Approach to
%   solving the cubic: Cardan's solution revealed,''
%   The Mathematical Gazette, 77(480)354-359, 1993.
%   dicknickalls@compuserve.com

%  Herman Bruyninckx 10 DEC 1996, 19 MAY 1999
%  Herman.Bruyninckx@mech.kuleuven.ac.be 
%  Dept. Mechanical Eng., Div. PMA, Katholieke Universiteit Leuven, Belgium
%  <http://www.mech.kuleuven.ac.be/~bruyninc>
%
%  Modified by Andrew Stein (University of Michigan) to 
%  handle vectors of coefficients
%
% THIS SOFTWARE COMES WITHOUT GUARANTEE.

sa = size(a); sb = size(b); sc = size(c); sd = size(d);
if any ( sa~=sb | sb~=sc | sc~=sd | sd~=sa)
    error('all vectors must be of equal size')
end
if all(sa~=1)
    error('function only accepts vectors')
end
if any(abs(a)<eps) 
  error('Coefficient of highest power must not be zero!\n'); 
end;

x = NaN * ones(length(a),3);

xN = -b/3./a;
yN = d + xN .* (c + xN .* (b + a.*xN));

two_a    = 2*a;
delta_sq = (b.*b-3.*a.*c)./(9*a.*a);
h_sq     = two_a .* two_a .* delta_sq.^3;
dis      = yN.*yN - h_sq;
pow      = 1/3;

ii = find(dis>=eps);
  % one real root:
  dis_sqrt = sqrt(dis(ii));
  r_p  = yN(ii) - dis_sqrt;
  r_q  = yN(ii) + dis_sqrt;
  p    = -sign(r_p) .* ( sign(r_p).*r_p./two_a(ii) ).^pow;
  q    = -sign(r_q) .* ( sign(r_q).*r_q./two_a(ii) ).^pow;
  x(ii,1) = xN(ii) + p + q;
  x(ii,2) = xN(ii) + p .* exp(2*pi*i/3) + q * exp(-2*pi*i/3);
  x(ii,3) = conj(x(ii,2));
ii = find(dis < -eps);
  % three distinct real roots:
  theta = acos(-yN(ii)./sqrt(h_sq(ii)))/3;
  delta = sqrt(delta_sq(ii));
  two_d = 2*delta;
  twop3 = 2*pi/3;
  x(ii,1) = xN(ii) + two_d.*cos(theta);
  x(ii,2) = xN(ii) + two_d.*cos(twop3-theta);
  x(ii,3) = xN(ii) + two_d.*cos(twop3+theta);
ii = find(dis<eps & dis >= -eps);
  % three real roots (two or three equal):
  delta = (yN(ii)./two_a(ii)).^pow;
  x(ii,1) = xN(ii) + delta; 
  x(ii,2) = xN(ii) + delta; 
  x(ii,3) = xN(ii) - 2*delta;

endfunction

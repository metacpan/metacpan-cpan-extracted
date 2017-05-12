#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols trig=>1;
use Test::More tests => 64;

($x, $y, $pi) = symbols(qw(x y pi));
   
# Reciprocals
ok(  sin($x) == 1/csc($x));
ok(  cos($x) == 1/sec($x));
ok(  tan($x) == 1/cot($x));
ok(  csc($x) == 1/sin($x));
ok(  sec($x) == 1/cos($x));
ok(  cot($x) == 1/tan($x));
                           
# Pythagoras

ok(  sin($x)**2 + cos($x)**2 == 1);
ok(  sec($x)**2 - tan($x)**2 == 1);
ok(  csc($x)**2 - cot($x)**2 == 1);

# Quotient  

ok(  tan($x) == sin($x)/cos($x));
ok(  cot($x) == cos($x)/sin($x));

# Co-Function Identities

ok(  sin($x) == cos($pi/2-$x));
ok(  cos($x) == sin($pi/2-$x));
ok(  cot($x) == tan($pi/2-$x));
ok(  sec($x) == csc($pi/2-$x));
ok(  csc($x) == sec($pi/2-$x));
ok(  tan($x) == cot($pi/2-$x));

# Even-Odd Identities
                         
ok(  cos($x) ==  cos(-$x));
ok(  sin($x) == -sin(-$x));
ok(  tan($x) == -tan(-$x));
ok(  cot($x) == -cot(-$x));
ok(  csc($x) == -csc(-$x));
ok(  sec($x) ==  sec(-$x));

# Values of sin, cos at well known points

ok(  cos(symbols(0))==   1);
ok(  cos($pi/2)     ==   0);
ok(  cos($pi)       ==  -1);
ok(  cos(3*$pi/2)   ==   0);
ok(  cos(4*$pi/2)   ==   1);
ok(  sin(symbols(0))==   0);
ok(  sin($pi/2)     ==   1);
ok(  sin($pi)       ==   0);
ok(  sin(3*$pi/2)   ==  -1);
ok(  sin(4*$pi/2)   ==   0);

# Sums and Differences
                                                 
ok(  sin($x+$y) == sin($x)*cos($y)+cos($x)*sin($y));
ok(  sin($x-$y) == sin($x)*cos($y)-cos($x)*sin($y));
ok(  cos($x+$y) == cos($x)*cos($y)-sin($x)*sin($y));
ok(  cos($x-$y) == cos($x)*cos($y)+sin($x)*sin($y));
ok(  tan($x+$y) == (tan($x)+tan($y))/(1-tan($x)*tan($y)));
ok(  tan($x-$y) == (tan($x)-tan($y))/(1+tan($x)*tan($y)));

# Double angles        
                                           
ok(  sin(2*$x) == 2*sin($x)*cos($x));
ok(  cos(2*$x) == cos($x)**2-sin($x)**2);
ok(  cos(2*$x) == 2*cos($x)**2-1);
ok(  cos(2*$x) == 1-2*sin($x)**2);
ok(  tan(2*$x) == 2*tan($x)/(1-tan($x)**2));

# Power-Reducing/Half Angle Formulas       
                                                            
ok(  sin($x)**2 == (1-cos(2*$x))/2);
ok(  cos($x)**2 == (1+cos(2*$x))/2);
ok(  tan($x)**2 == (1-cos(2*$x))/(1+cos(2*$x)));

# Sum-to-Product Formulas      
                                                            
ok(  sin($x)+sin($y) ==  2*sin(($x+$y)/2)*cos(($x-$y)/2));
ok(  sin($x)-sin($y) ==  2*cos(($x+$y)/2)*sin(($x-$y)/2));
ok(  cos($x)+cos($y) ==  2*cos(($x+$y)/2)*cos(($x-$y)/2));
ok(  cos($x)-cos($y) == -2*sin(($x+$y)/2)*sin(($x-$y)/2));

# Product-to-Sum Formulas       
                                                   
ok(  sin($x)*sin($y) == cos($x-$y)/2-cos($x+$y)/2);
ok(  cos($x)*cos($y) == cos($x-$y)/2+cos($x+$y)/2);
ok(  sin($x)*cos($y) == sin($x+$y)/2+sin($x-$y)/2);
ok(  cos($x)*sin($y) == sin($x+$y)/2-sin($x-$y)/2);

# Differentials.

ok(  cos($x)    == -cos($x)->d->d);
ok(  sin($x)    == -sin($x)->d->d);
ok(  sin($x)->d ==  cos($x));
ok(  cos($x)->d == -sin($x));
ok(  tan($x)->d ==  tan($x)**2 + 1);
ok(  tan($x)->d ==  sec($x)**2);
ok(  cot($x)->d == -csc($x)**2);
ok(  sec($x)->d ==  sec($x)*tan($x));
ok(  csc($x)->d == -csc($x)*cot($x));


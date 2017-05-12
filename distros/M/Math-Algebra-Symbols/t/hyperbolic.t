#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols hyper=>1, trig=>1;
use Test::More tests => 20;

($x, $y, $i) = symbols(qw(x y i));

ok(  cosh($x)->d == sinh($x));
ok(  sinh($x)->d == cosh($x));

ok(  cosh($x)**2-sinh($x)**2 == 1);
ok(  cosh($x+$y)             == cosh($x)*cosh($y)+sinh($x)*sinh($y));
ok(  sinh($x+$y)             == sinh($x)*cosh($y)+cosh($x)*sinh($y));

# Reciprocal

ok(  sinh($x) == 1/csch($x));
ok(  cosh($x) == 1/sech($x));
ok(  tanh($x) == 1/coth($x));
ok(  csch($x) == 1/sinh($x));
ok(  sech($x) == 1/cosh($x));
ok(  coth($x) == 1/tanh($x));

# Pythagoras

ok(  cosh($x)**2 - sinh($x)**2 == 1);
ok(  tanh($x)**2 + sech($x)**2 == 1);
ok(  coth($x)**2 - csch($x)**2 == 1);

# Relations to Trigonometric Function

ok(  sinh($x) == -$i*sin($i*$x));
ok(  csch($x) ==  $i*csc($i*$x));
ok(  cosh($x) ==     cos($i*$x));
ok(  sech($x) ==     sec($i*$x));
ok(  tanh($x) == -$i*tan($i*$x));
ok(  coth($x) ==  $i*cot($i*$x));


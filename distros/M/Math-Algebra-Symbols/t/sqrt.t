#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::More tests => 11;

($x, $y) = symbols(qw(x y));

ok(  sqrt(($x+$y)**2)+$x-$y                                                == 2*$x);
ok(  sqrt(($x+$y)**2)+sqrt(($x-$y)**2)                                     == 2*$x);
ok(  sqrt(($x+$y)**2)+sqrt(($x-$y)**2)+sqrt((-$x+$y)**2)+sqrt((-$x-$y)**2) == 4*$x);
ok( ($x*sqrt($x))->d                                                       == 3*sqrt($x)/2);
ok(  sqrt($x**3)->d                                                        == symbols('3/2')*sqrt($x));
ok(((1+$x)/sqrt(1+$x))->d                                                  == sqrt(1+$x)->d);

ok(  sqrt($x+1) / sqrt(1+$x)                == 1);
ok(  2*$y**2*sqrt($x+1) / (4*$y*sqrt(1+$x)) == $y/2);
ok(  1/sqrt(1+$x)                           == 1/sqrt(1+$x));
ok(  1/sqrt(1+$x)**3                        == 1/(sqrt(1+$x)+sqrt(1+$x)*$x));
ok(  sqrt($x+1)**3 / sqrt(1+$x)**3          == 1);


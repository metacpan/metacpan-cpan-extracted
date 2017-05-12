#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra: quadratic equation.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests => 2;

my ($x) = symbols(qw(x));

my  $p = $x**2-5*$x+6;        # Quadratic polynomial
my ($a, $b) = @{($p > $x )};  # Solve for x

print "x=$a,$b\n";            # Roots

ok($a == 2);
ok($b == 3);


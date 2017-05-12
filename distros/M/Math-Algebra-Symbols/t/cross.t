#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: cross operator.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>3;

my ($x, $i) = symbols(qw(x i));

ok(  $i*$x x $x  ==  $x**2  );
ok(  $i*$x x $x  !=  $x**3  );
ok(  $i*$x x $x <=> '$x**2' );


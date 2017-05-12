#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: sqrt(-1).
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>2;

my ($x, $i) = symbols(qw(x i));

ok(  sqrt(-$x**2)  ==  $i*$x  );
ok(  sqrt(-$x**2)  <=> '&i*$x' );



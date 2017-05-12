#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: constants.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>1;

my ($x, $y, $i, $o, $pi) = symbols(qw(x y i 1 pi));

ok( "$x $y $i $o $pi"   eq   '$x $y &i 1 $pi'  );


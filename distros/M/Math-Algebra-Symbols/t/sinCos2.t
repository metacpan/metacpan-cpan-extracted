#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: methods.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>1;

my ($x, $y) = symbols(qw(x y));

ok( (sin($x)**2 == (1-cos(2*$x))/2) );


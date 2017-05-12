#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: methods.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols hyper=>1;
use Test::Simple tests=>1;

my ($x, $y) = symbols(qw(x y));

ok( tanh($x+$y)==(tanh($x)+tanh($y))/(1+tanh($x)*tanh($y)));


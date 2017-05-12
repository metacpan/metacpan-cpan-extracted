#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: log: need better example.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>1;

my ($x) = symbols(qw(x));

ok(   log($x) <=>  'log($x)' );



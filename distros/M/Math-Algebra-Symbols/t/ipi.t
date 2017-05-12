#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: constants.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>2;

my ($i, $pi) = symbols(qw(i pi));

ok(  exp($i*$pi)  ==   -1  );
ok(  exp($i*$pi) <=>  '-1' );


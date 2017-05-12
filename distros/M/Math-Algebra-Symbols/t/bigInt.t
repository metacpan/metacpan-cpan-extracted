#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: bigInt.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>1;

my $z = symbols('1234567890987654321/1234567890987654321');

ok( eval $z eq '1');


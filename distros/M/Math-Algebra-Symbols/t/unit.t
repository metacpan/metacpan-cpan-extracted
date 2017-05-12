#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: unit operator.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>4;

my ($i) = symbols(qw(i));

ok(  !$i      == $i                          );
ok(  !$i     <=> '&i'                        );
ok(  !($i+1) <=>  '1/(sqrt(2))+&i/(sqrt(2))' );
ok(  !($i-1) <=> '-1/(sqrt(2))+&i/(sqrt(2))' );


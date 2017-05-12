#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: methods.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>2;

my ($x, $i) = symbols(qw(x i));

ok( ($i*$x)->re   <=>  0    );
ok( ($i*$x)->im   <=>  '$x' );


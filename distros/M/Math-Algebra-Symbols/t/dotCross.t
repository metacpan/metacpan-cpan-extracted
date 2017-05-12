#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: methods.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>2;

my $i = symbols(qw(i));

ok( ($i+1)->cross($i-1)   <=>  2 );
ok( ($i+1)->dot  ($i-1)   <=>  0 );


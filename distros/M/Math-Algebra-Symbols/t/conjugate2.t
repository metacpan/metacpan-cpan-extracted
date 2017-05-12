#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: methods.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>3;

my $i = symbols(qw(i));

ok( ($i+1)->unit      <=>  '1/(sqrt(2))+&i/(sqrt(2))');
ok( ($i+1)->modulus   <=>  'sqrt(2)'                 );
ok( ($i+1)->conjugate <=>  '1-&i'                    );


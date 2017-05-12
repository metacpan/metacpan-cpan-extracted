#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: simplify.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>2;
 
my ($t) = symbols(qw(t));

my $rabbit  = 10 + 5 * $t;
my $fox     = 7 * $t * $t;
my ($a, $b) = @{($rabbit eq $fox) > $t};

ok( "$a" eq  '1/14*sqrt(305)+5/14'  );      
ok( "$b" eq '-1/14*sqrt(305)+5/14'  );      


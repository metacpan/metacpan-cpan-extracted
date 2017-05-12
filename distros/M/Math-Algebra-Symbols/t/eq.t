#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: solving.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>3;

my ($x, $v, $t) = symbols(qw(x v t));

ok(  ($v eq $x / $t)->solve(qw(x in terms of v t))  ==  $v*$t  );
ok(  ($v eq $x / $t)->solve(qw(x in terms of v t))  !=  $v+$t  );
ok(  ($v eq $x / $t)->solve(qw(x in terms of v t)) <=> '$t*$v' );



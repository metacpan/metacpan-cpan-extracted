#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::More tests => 22;

($zero, $half, $one, $pi, $x) = symbols(qw(0 1/2 1 pi x));
           
ok(  sin($zero)          == -0);
ok(  sin($pi/6)          ==  $half);
ok(  sin($pi/2)          ==  1);
ok(  sin(5*$pi/6)        ==  $half);
ok(  sin(120*$pi/120)    ==  $zero);
ok(  sin(7*$pi/6)        == -$half);
ok(  sin(3*$pi/2)        == -1);
ok(  sin(110*$pi/ 60)    == '-1/2');
ok(  sin(2*$pi)          ==  $zero);
ok(  sin(-$zero)         ==  $zero);
ok(  sin(-$pi/6)         == -$half);
ok(  sin(-$pi/2)         == -$one);
ok(  sin(-5*$pi/6)       == -$half);
ok(  sin(-120*$pi/120)   == -$zero);
ok(  sin(-7*$pi/6)       ==  $half);
ok(  sin(-3*$pi/2)       ==  $one);
ok(  sin(-110*$pi/ 60)   ==  $half);

ok(  sin(-2*$pi)         ==  $zero);
ok(  sin($x)->d          ==  cos($x));
ok(  sin($x)->d->d       == -sin($x));
ok(  sin($x)->d->d->d    == -cos($x));
ok(  sin($x)->d->d->d->d ==  sin($x));


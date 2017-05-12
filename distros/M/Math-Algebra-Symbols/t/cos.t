#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::More tests => 22;

($zero, $half, $one, $pi, $x) = symbols(qw(0 1/2 1 pi x));
           
ok(  cos($zero)          ==  $one);
ok(  cos($pi/3)          ==  $half);
ok(  cos($pi/2)          ==  $zero);
ok(  cos(4*$pi/6)        == -$half);
ok(  cos(120*$pi/120)    == -$one);
ok(  cos(8*$pi/6)        == -$half);
ok(  cos(3*$pi/2)        ==  $zero);
ok(  cos(100*$pi/ 60)    ==  $half);
ok(  cos(2*$pi)          ==  $one);
ok(  cos(-$zero)         ==  $one);
ok(  cos(-$pi/3)         == +$half);
ok(  cos(-$pi/2)         ==  $zero);
ok(  cos(-4*$pi/6)       == -$half);
ok(  cos(-120*$pi/120)   == -$one);
ok(  cos(-8*$pi/6)       == -$half);
ok(  cos(-3*$pi/2)       ==  $zero);
ok(  cos(-100*$pi/ 60)   ==  $half);
ok(  cos(-2*$pi)         ==  $one);
ok(  cos($x)->d          == -sin($x));
ok(  cos($x)->d->d       == -cos($x));
ok(  cos($x)->d->d->d    ==  sin($x));
ok(  cos($x)->d->d->d->d ==  cos($x));


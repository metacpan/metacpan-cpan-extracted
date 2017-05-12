#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::More tests => 5;

$x = symbols(qw(x));
           
ok(  sin($x)    ==  sin($x)->d->d->d->d);
ok(  cos($x)    ==  cos($x)->d->d->d->d);
ok(  exp($x)    ==  exp($x)->d($x)->d('x')->d->d);
ok( (1/$x)->d   == -1/$x**2);
ok(  exp($x)->d->d->d->d <=> 'exp($x)' );


#!perl -T

use warnings;
use strict;

use Test::More tests => 5;

use lib 'lib';
use Math::Function::Roots qw(secant last_iter epsilon max_iter);

epsilon(0);
is( epsilon(), 0, "epsilon set/get" );
is( secant( sub{shift()**2-4}, .2, .3 ), 2, "secant: f(x)=x**2-4");

max_iter(0);
is( max_iter(), 1, "max_iter set minimum" );
{ $SIG{'__WARN__'} = sub {}; #Turn warnings off for cleaner output
  secant( sub{shift()**2-4}, .2, .3 );
}
is( last_iter(), 1, "secant: cut short");

epsilon(.0001);
max_iter(50_000);
ok( abs( secant( sub{shift()**2-4}, .2, .3 ) - 2 ) <= epsilon(), "normal secant operation");

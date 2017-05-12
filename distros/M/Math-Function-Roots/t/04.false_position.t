#!perl -T

use warnings;
use strict;

use Test::More tests => 8;

use lib 'lib';
use Math::Function::Roots qw(false_position last_iter epsilon max_iter);

cmp_ok( abs(false_position( sub{shift()**2-4}, 0, 5 ) - 2), '<' ,epsilon(), "false_position: f(x)=x**2-4");

epsilon(0);
is( epsilon(), 0, "epsilon set/get" );
is( false_position( sub{shift()**2-4}, 0, 5 ), 2, "false_position: f(x)=x**2-4");

max_iter(0);
is( max_iter(), 1, "max_iter set minimum" );
{ $SIG{'__WARN__'} = sub {}; #Turn warnings off for cleaner output
  false_position( sub{shift()**2-4}, 0, 5 );
}
is( last_iter(), 1, "false_position: cut short");

epsilon(.0001);
max_iter(50_000);
ok( abs( false_position( sub{shift()**2-4}, 0, 5 ) - 2 ) <= epsilon(), "normal false_position operation");


ok( abs( false_position( sub{sin(shift())}, .2, 6 ) - 3.1415927 ) <= epsilon(), 
    "normal false_position operation");


#Test error passing

eval{
    ok( abs( false_position( sub{shift()**2-4}, -5, 5 ) - 2 ) <= epsilon(), "normal false_position operation");
};
like( $@, qr/^Bad range/ , "Correct Error on bad range");

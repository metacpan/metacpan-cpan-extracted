#!perl
use strict;
use warnings;
use Test::More;
use Math::Fractal::Julia;

can_ok( 'Math::Fractal::Julia',
    qw( set_max_iter set_limit set_bounds set_constant ) );

eval {
    Math::Fractal::Julia->set_max_iter(4);
    pass('set_max_iter');
    1;
} or do {
    fail('set_max_iter');
};

eval {
    Math::Fractal::Julia->set_bounds( -1, -1, 1, 1, 640, 480 );
    pass('set_bounds');
    1;
} or do {
    fail('set_bounds');
};

eval {
    Math::Fractal::Julia->set_constant( 0.5, 0.5 );
    pass('set_constant');
    1;
} or do {
    fail('set_constant');
};

is( Math::Fractal::Julia->point( 320, 240 ), 0, 'point' );

isnt( Math::Fractal::Julia->point( 0, 0 ), 0, 'point' );

done_testing();


#!perl
use strict;
use warnings;
use Test::More;
use Math::Fractal::Julia;

can_ok( 'Math::Fractal::Julia',
    qw( new set_max_iter set_limit set_bounds set_constant ) );

my $julia = Math::Fractal::Julia->new();

ok( $julia, 'new' );

isa_ok( $julia, 'Math::Fractal::Julia' );

eval {
    $julia->set_max_iter(4);
    pass('set_max_iter');
    1;
} or do {
    fail('set_max_iter');
};

eval {
    $julia->set_bounds( -1, -1, 1, 1, 640, 480 );
    pass('set_bounds');
    1;
} or do {
    fail('set_bounds');
};

eval {
    $julia->set_constant( 0.5, 0.5 );
    pass('set_constant');
    1;
} or do {
    fail('set_constant');
};

is( $julia->point( 320, 240 ), 0, 'point' );

isnt( $julia->point( 0, 0 ), 0, 'point' );

done_testing();


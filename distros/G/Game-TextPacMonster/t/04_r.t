use strict;
use warnings;
use utf8;

use Test::More 'no_plan';
use Test::MockObject;

use Game::TextPacMonster::R;

my $ID    = 2;
my $X     = 10;
my $Y     = 10;
my $POINT = Game::TextPacMonster::Point->new( $X, $Y );

&test_new;
&test_move_free_after_moved_left_to_right;
&test_move_free_after_moved_right_to_left;
&test_move_free_after_moved_up_to_down;
&test_move_free_after_moved_down_to_up;

sub test_new {
    my $map = Test::MockObject->new();
    my $creature = Game::TextPacMonster::R->new( $ID, $POINT, $map );

    isa_ok( $creature, 'Game::TextPacMonster::R' );
    isa_ok( $creature, 'Game::TextPacMonster::Creature' );
}

sub test_move_free_after_moved_left_to_right {
    my $map  = Test::MockObject->new();
    my @rule = (
        1,    # move right
        1,    # inner move down
        1,    # move right
        0,    # deny inner move down
        1,    # inner move right
        1,    # move right
        0,    # deny inner move down
        0,    # deny inner move right
        1,    # inner move move up
        1,    # move right
        0,    # deny inner move down
        0,    # deny inner move right
        0,    # deny inner move move up
    );
    $map->set_series( 'can_move', @rule );

    my $creature = Game::TextPacMonster::R->new( $ID, $POINT, $map );
    my $preparing_method = 'move_right';

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X + 1 );
    is( $creature->point->y_coord, $Y );

    ok( $creature->move_free, 'PASS: It is expected to move down' );
    is( $creature->point->x_coord, $X + 1 );
    is( $creature->point->y_coord, $Y + 1 );

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X + 2 );
    is( $creature->point->y_coord, $Y + 1 );

    ok( $creature->move_free, 'PASS: It is expected to move right' );
    is( $creature->point->x_coord, $X + 3 );
    is( $creature->point->y_coord, $Y + 1 );

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X + 4 );
    is( $creature->point->y_coord, $Y + 1 );

    ok( $creature->move_free, 'PASS: It is expected to move up' );
    is( $creature->point->x_coord, $X + 4 );
    is( $creature->point->y_coord, $Y );

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X + 5 );
    is( $creature->point->y_coord, $Y );

    ok( !$creature->move_free, 'PASS: It is expected to return fault' );
}

sub test_move_free_after_moved_right_to_left {
    my $map  = Test::MockObject->new();
    my @rule = (
        1,    # move left
        1,    # inner move up
        1,    # move left
        0,    # deny inner move up
        1,    # inner move left
        1,    # move left
        0,    # deny inner move up
        0,    # deny inner move left
        1,    # inner move move down
        1,    # move left
        0,    # deny inner move up
        0,    # deny inner move left
        0,    # deny inner move move down
    );
    $map->set_series( 'can_move', @rule );

    my $creature = Game::TextPacMonster::R->new( $ID, $POINT, $map );
    my $preparing_method = 'move_left';

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X - 1 );
    is( $creature->point->y_coord, $Y );

    ok( $creature->move_free, 'PASS: It is expected to move up' );
    is( $creature->point->x_coord, $X - 1 );
    is( $creature->point->y_coord, $Y - 1 );

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X - 2 );
    is( $creature->point->y_coord, $Y - 1 );

    ok( $creature->move_free, 'PASS: It is expected to move left' );
    is( $creature->point->x_coord, $X - 3 );
    is( $creature->point->y_coord, $Y - 1 );

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X - 4 );
    is( $creature->point->y_coord, $Y - 1 );

    ok( $creature->move_free, 'PASS: It is expected to move down' );
    is( $creature->point->x_coord, $X - 4 );
    is( $creature->point->y_coord, $Y );

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X - 5 );
    is( $creature->point->y_coord, $Y );

    ok( !$creature->move_free, 'PASS: It is expected to return fault' );
}

sub test_move_free_after_moved_up_to_down {
    my $map  = Test::MockObject->new();
    my @rule = (
        1,    # move down
        1,    # inner move left
        1,    # move down
        0,    # deny inner move left
        1,    # inner move down
        1,    # move down
        0,    # deny inner move left
        0,    # deny inner move down
        1,    # inner move move right
        1,    # move down
        0,    # deny inner move left
        0,    # deny inner move down
        0,    # deny inner move right
    );
    $map->set_series( 'can_move', @rule );

    my $creature = Game::TextPacMonster::R->new( $ID, $POINT, $map );

    my $preparing_method = 'move_down';

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y + 1 );

    ok( $creature->move_free, 'PASS: It is expected to move left' );
    is( $creature->point->x_coord, $X - 1 );
    is( $creature->point->y_coord, $Y + 1 );

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X - 1 );
    is( $creature->point->y_coord, $Y + 2 );

    ok( $creature->move_free, 'PASS: It is expected to move down' );
    is( $creature->point->x_coord, $X - 1 );
    is( $creature->point->y_coord, $Y + 3 );

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X - 1 );
    is( $creature->point->y_coord, $Y + 4 );

    ok( $creature->move_free, 'PASS: It is expected to move right' );
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y + 4 );

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y + 5 );

    ok( !$creature->move_free, 'PASS: It is expected to return fault' );
}

sub test_move_free_after_moved_down_to_up {
    my $map  = Test::MockObject->new();
    my @rule = (
        1,    # move up
        1,    # inner move right
        1,    # move up
        0,    # deny inner move right
        1,    # inner move up
        1,    # move up
        0,    # deny inner move right
        0,    # deny inner move up
        1,    # inner move move left
        1,    # move up
        0,    # deny inner move left
        0,    # deny inner move down
        0,    # deny inner move right
    );
    $map->set_series( 'can_move', @rule );

    my $creature = Game::TextPacMonster::R->new( $ID, $POINT, $map );

    my $preparing_method = 'move_up';

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y - 1 );

    ok( $creature->move_free, 'PASS: It is expected to move right' );
    is( $creature->point->x_coord, $X + 1 );
    is( $creature->point->y_coord, $Y - 1 );

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X + 1 );
    is( $creature->point->y_coord, $Y - 2 );

    ok( $creature->move_free, 'PASS: It is expected to move up' );
    is( $creature->point->x_coord, $X + 1 );
    is( $creature->point->y_coord, $Y - 3 );

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X + 1 );
    is( $creature->point->y_coord, $Y - 4 );

    ok( $creature->move_free, 'PASS: It is expected to move left' );
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y - 4 );

    ok( $creature->$preparing_method, 'PASS: prepare' );
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y - 5 );

    ok( !$creature->move_free, 'PASS: It is expected to return fault' );
}


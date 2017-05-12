use strict;
use warnings;
use utf8;

use Test::More 'no_plan';
use Test::MockObject;

use Game::TextPacMonster::H;

my $ID    = 2;
my $X     = 10;
my $Y     = 10;
my $POINT = Game::TextPacMonster::Point->new( $X, $Y );

&test_new;
&test_move_free_player_under_h;
&test_move_free_player_above_h;
&test_move_free_player_on_h_right;
&test_move_free_player_on_h_left;
&test_move_free_false;
&test_move_free_default_first_move;
&test_move_free_default_2nd_move;
&test_move_free_default_3rd_move;
&test_move_free_default_4th_move;
&test_move_free_same_place;

sub test_new {
    my $map = Test::MockObject->new();
    my $creature = Game::TextPacMonster::H->new( $ID, $POINT, $map );

    isa_ok( $creature, 'Game::TextPacMonster::H' );
    isa_ok( $creature, 'Game::TextPacMonster::Creature' );
}

sub test_move_free_player_under_h {
    my $player_x = $X;
    my $player_y = $Y + 1;
    my $player_p = Game::TextPacMonster::Point->new( $player_x, $player_y );

    my $map = Test::MockObject->new();
    $map->set_true('can_move');
    $map->mock( 'get_player_point', sub { $player_p } );

    my $creature = Game::TextPacMonster::H->new( $ID, $POINT, $map );

    ok( $creature->move_free );
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y + 1 );
}

sub test_move_free_player_above_h {
    my $player_x = $X;
    my $player_y = $Y - 1;
    my $player_p = Game::TextPacMonster::Point->new( $player_x, $player_y );

    my $map = Test::MockObject->new();
    $map->set_true('can_move');
    $map->mock( 'get_player_point', sub { $player_p } );

    my $creature = Game::TextPacMonster::H->new( $ID, $POINT, $map );

    ok( $creature->move_free );
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y - 1 );
}

sub test_move_free_player_on_h_right {
    my $player_x = $X + 1;
    my $player_y = $Y + 2;
    my $player_p = Game::TextPacMonster::Point->new( $player_x, $player_y );

    my $map = Test::MockObject->new();
    $map->set_true('can_move');
    $map->mock( 'get_player_point', sub { $player_p } );

    my $creature = Game::TextPacMonster::H->new( $ID, $POINT, $map );

    ok( $creature->move_free );
    is( $creature->point->x_coord, $X + 1 );
    is( $creature->point->y_coord, $Y );
}

sub test_move_free_player_on_h_left {
    my $player_x = $X - 1;
    my $player_y = $Y + 2;
    my $player_p = Game::TextPacMonster::Point->new( $player_x, $player_y );

    my $map = Test::MockObject->new();
    $map->set_true('can_move');
    $map->mock( 'get_player_point', sub { $player_p } );

    my $creature = Game::TextPacMonster::H->new( $ID, $POINT, $map );

    ok( $creature->move_free );
    is( $creature->point->x_coord, $X - 1 );
    is( $creature->point->y_coord, $Y );
}

sub test_move_free_default_first_move {
    my $player_x = $X - 1;
    my $player_y = $Y;
    my $player_p = Game::TextPacMonster::Point->new( $player_x, $player_y );

    my $map = Test::MockObject->new();
    $map->set_series( 'can_move', ( 0, 1 ) );
    $map->mock( 'get_player_point', sub { $player_p } );

    my $creature = Game::TextPacMonster::H->new( $ID, $POINT, $map );

    ok( $creature->move_free );
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y + 1 );
}

sub test_move_free_default_2nd_move {
    my $player_x = $X + 1;
    my $player_y = $Y;
    my $player_p = Game::TextPacMonster::Point->new( $player_x, $player_y );

    my $map = Test::MockObject->new();
    $map->set_series( 'can_move', ( 0, 0, 1 ) );
    $map->mock( 'get_player_point', sub { $player_p } );

    my $creature = Game::TextPacMonster::H->new( $ID, $POINT, $map );

    ok( $creature->move_free );
    is( $creature->point->x_coord, $X - 1 );
    is( $creature->point->y_coord, $Y );
}

sub test_move_free_default_3rd_move {
    my $player_x = $X + 1;
    my $player_y = $Y;
    my $player_p = Game::TextPacMonster::Point->new( $player_x, $player_y );

    my $map = Test::MockObject->new();
    $map->set_series( 'can_move', ( 0, 0, 0, 1 ) );
    $map->mock( 'get_player_point', sub { $player_p } );

    my $creature = Game::TextPacMonster::H->new( $ID, $POINT, $map );

    ok( $creature->move_free );
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y - 1 );
}

sub test_move_free_default_4th_move {
    my $player_x = $X + 1;
    my $player_y = $Y;
    my $player_p = Game::TextPacMonster::Point->new( $player_x, $player_y );

    my $map = Test::MockObject->new();
    $map->set_series( 'can_move', ( 0, 0, 0, 0, 1 ) );
    $map->mock( 'get_player_point', sub { $player_p } );

    my $creature = Game::TextPacMonster::H->new( $ID, $POINT, $map );

    ok( $creature->move_free );
    is( $creature->point->x_coord, $X + 1 );
    is( $creature->point->y_coord, $Y );
}

sub test_move_free_same_place {
    my $player_x = $X;
    my $player_y = $Y;
    my $player_p = Game::TextPacMonster::Point->new( $player_x, $player_y );

    my $map = Test::MockObject->new();
    $map->set_true('can_move');
    $map->mock( 'get_player_point', sub { $player_p } );

    my $creature = Game::TextPacMonster::H->new( $ID, $POINT, $map );

    ok( $creature->move_free );
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y + 1 );
}

sub test_move_free_false {
    my $player_x = $X - 1;
    my $player_y = $Y;
    my $player_p = Game::TextPacMonster::Point->new( $player_x, $player_y );

    my $map = Test::MockObject->new();
    $map->set_false('can_move');
    $map->mock( 'get_player_point', sub { $player_p } );

    my $creature = Game::TextPacMonster::H->new( $ID, $POINT, $map );

    ok( !$creature->move_free );
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y );
}


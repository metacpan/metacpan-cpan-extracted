use strict;
use warnings;
use utf8;

use Test::More 'no_plan';
use Test::MockObject;

use Game::TextPacMonster::Player;

my $ID    = 2;
my $X     = 10;
my $Y     = 10;
my $POINT = Game::TextPacMonster::Point->new( $X, $Y );

&test_new;
&test_move;
&test__get_function;
&test_can_move;

sub test_can_move {

    my $map = Test::MockObject->new();
    $map->set_false('can_move');
    my $creature = Game::TextPacMonster::Player->new( $ID, $POINT, $map );

    ok( !$creature->can_move );
    ok( !$creature->can_move('a') );

    # test about j
    ok( !$creature->can_move('j') );
    my $point = Game::TextPacMonster::Point->new( $X, $Y + 1 );
    $map->mock(
        'can_move',
        sub {
            my ( $self, $p ) = @_;
            my $mock_point = $point;
            return $mock_point->equals($p);
        }
    );
    ok( $creature->can_move('j') );

    #test about k
    ok( !$creature->can_move('k') );
    $point = Game::TextPacMonster::Point->new( $X, $Y - 1 );
    ok( $creature->can_move('k') );

    #test about h
    ok( !$creature->can_move('h') );
    $point = Game::TextPacMonster::Point->new( $X - 1, $Y );
    ok( $creature->can_move('h') );

    #test about l
    ok( !$creature->can_move('l') );
    $point = Game::TextPacMonster::Point->new( $X + 1, $Y );
    ok( $creature->can_move('l') );
}

sub test__get_function {
    my $map = Test::MockObject->new();
    my $creature = Game::TextPacMonster::Player->new( $ID, $POINT, $map );

    is( $creature->_get_function('.'), 'stay' );
    is( $creature->_get_function('j'), 'move_down' );
    is( $creature->_get_function('k'), 'move_up' );
    is( $creature->_get_function('h'), 'move_left' );
    is( $creature->_get_function('l'), 'move_right' );

    is( $creature->_get_function('a'), 0 );
    is( $creature->_get_function,      0 );
}

sub test_new {
    my $map = Test::MockObject->new();
    my $creature = Game::TextPacMonster::Player->new( $ID, $POINT, $map );

    isa_ok( $creature, 'Game::TextPacMonster::Player' );
    isa_ok( $creature, 'Game::TextPacMonster::Creature' );
}

sub test_move {
    my $map = Test::MockObject->new();
    $map->set_true('can_move')->set_true('del_feed');

    my $creature = Game::TextPacMonster::Player->new( $ID, $POINT, $map );

    ok( !$creature->move('a'), 'test_move' );    # wrong command

    ok( $creature->move('.'), 'test_move' );
    is( $creature->point->x_coord, $X, 'test_move' );
    is( $creature->point->y_coord, $Y );

    ok( $creature->move('j'), 'test_move' );
    is( $creature->point->x_coord, $X,     'test_move' );
    is( $creature->point->y_coord, $Y + 1, 'test_move' );

    ok( $creature->move('k'), 'test_move' );
    is( $creature->point->x_coord, $X, 'test_move' );
    is( $creature->point->y_coord, $Y, 'test_move' );

    ok( $creature->move('h'), 'test_move' );
    is( $creature->point->x_coord, $X - 1, 'test_move' );
    is( $creature->point->y_coord, $Y,     'test_move' );

    ok( $creature->move('l'), 'test_move' );
    is( $creature->point->x_coord, $X, 'test_move' );
    is( $creature->point->y_coord, $Y, 'test_move' );
}


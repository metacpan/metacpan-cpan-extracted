use strict;
use warnings;
use utf8;

use Test::More 'no_plan';
use Test::MockObject;

use Game::TextPacMonster::Creature;

my $ID    = 2;
my $X     = 5;
my $Y     = 2;
my $POINT = Game::TextPacMonster::Point->new( $X, $Y );

&test_new;
&test_id;
&test_point_as_getter;
&test_point_as_setter;
&test_pre_point;
&test_stay;
&test__move_point;
&test_get_player_point;
&test_move_left;
&test_move_right;
&test_move_down;
&test_move_up;
&test_move_back;
&test_move_first;
&test_move_forward;
&test_get_relative_point;
&test_move_free;
&test_move;

sub test_move {

    my $true = 1;

    # normal series
    my $map = Test::MockObject->new();
    $map->set_always( 'can_move', $true );
    $map->set_series( 'get_time', ( 0, 1, 2, 3, 4, 5 ) );
    $map->set_series( 'count_movable_points', ( 1, 2, 3 ) );

    my $creature = Game::TextPacMonster::Creature->new( $ID, $POINT, $map );

    ok( $creature->move );    # move_first
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y + 1 );

    ok( $creature->move );    # move_back;
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y );

    ok( $creature->move );    # move_forard;
    is( $creature->point->x_coord, $X + 1 );
    is( $creature->point->y_coord, $Y );

    eval { $creature->move; };
    like( $@, qr/^it should be overrided on sub class/, "PASS: die" );
}

sub test_move_free {
    my $creature = &init;
    eval { $creature->move_free; };
    like( $@, qr/^it should be overrided on sub class/, "PASS: die" );
}

sub test_get_relative_point {
    my $player_point_x = 4;
    my $player_point_y = 2;
    my $player_point   = Game::TextPacMonster::Point->new( $player_point_x, $player_point_y );

    my $map = Test::MockObject->new();
    $map->mock( 'get_player_point', sub { $player_point } );
    is( $map->get_player_point, $player_point, "PASS: mock surely create" );

    my $creature = Game::TextPacMonster::Creature->new( 12, $POINT, $map );
    my $relative_point = $creature->get_relative_point;

    is( $relative_point->x_coord, $player_point_x - $X );
    is( $relative_point->y_coord, $player_point_y - $Y );
}

sub test_move_forward {

    # normal series
    my $map           = Test::MockObject->new();
    my @can_move_rule = (
        1,    # allow move_up
        1,    # allow move_forward as going righ
        1,    # allow move_down
        0,    # deny move_forward as going right
        1,    # allow move_forward as going left
        1,    # allow move_right
        0,    # deny move forward as going right
         # dont'have a deny but fail to move forward as going left for pre_point
        1,    # allow move forward as goting down
        1,    # allow move move_left
         # don't have a deny but fail to move forward as going right for pre_point
        0,    # deny move forward as going left
        0,    # deny move forward as going down
        1,    # allow move forward as going up
    );

    $map->set_series( 'can_move', @can_move_rule );
    $map->set_always( 'get_time', 0 );

    my $creature = Game::TextPacMonster::Creature->new( $ID, $POINT, $map );

    $creature->move_up;
    ok( $creature->move_forward, 'PASS: went right' );
    is( $creature->point->x_coord, $X + 1, 'PASS: for move_forward' );
    is( $creature->point->y_coord, $Y - 1, 'PASS: for move_up' );

    $creature->move_down;
    ok( $creature->move_forward, 'PASS: went left' );
    is( $creature->point->x_coord, $X, 'PASS: for move_forward' );
    is( $creature->point->y_coord, $Y, 'PASS: for move_down' );

    $creature->move_right;
    ok( $creature->move_forward, 'PASS: went down' );
    is( $creature->point->x_coord, $X + 1, 'PASS: for move_right' );
    is( $creature->point->y_coord, $Y + 1, 'PASS: for move_forward' );

    $creature->move_left;
    ok( $creature->move_forward, 'PASS: went up' );
    is( $creature->point->x_coord, $X, 'PASS: for move_left' );
    is( $creature->point->y_coord, $Y, 'PASS: for move_forward' );

}

sub test_move_first {

    # normal series
    my $map = Test::MockObject->new();
    $map->set_series( 'can_move', ( 1, 0, 1, 0, 0, 1, 0, 0, 0, 1 ) );
    $map->set_always( 'get_time', 0 );

    my $creature = Game::TextPacMonster::Creature->new( $ID, $POINT, $map );

    ok( $creature->move_first );    # move_down
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y + 1 );

    $creature->move_first;          # move_left
    is( $creature->point->x_coord, $X - 1 );
    is( $creature->point->y_coord, $Y + 1 );

    $creature->move_first;          # move_up
    is( $creature->point->x_coord, $X - 1 );
    is( $creature->point->y_coord, $Y );

    $creature->move_first;          # move_right
    is( $creature->point->x_coord, $X );
    is( $creature->point->y_coord, $Y );

    # abnormal series
    # not 1st time
    my $map_after_one_time = Test::MockObject->new();
    $map_after_one_time->set_always( 'can_move', 1 );
    $map_after_one_time->set_always( 'get_time', 1 );

    my $creature_after_one_time = Game::TextPacMonster::Creature->new( $ID, $POINT, $map );
    ok( !$creature_after_one_time->move_first );

    #can not move
    my $unmovavle_map = Test::MockObject->new();
    $map->set_series( 'can_move', ( 0, 0, 0, 0, 1 ) );
    $map->set_always( 'get_time', 0 );

    my $unmovable_creature = Game::TextPacMonster::Creature->new( $ID, $POINT, $map );
    ok( !$unmovable_creature->move_first );
}

sub test_move_back {
    my $creature = &init;

    $creature->move_up;
    ok( $creature->move_back );
    is( $creature->point->x_coord,        $X );
    is( $creature->point->y_coord,        $Y );
    is( $creature->{_pre_point}->x_coord, $X );
    is( $creature->{_pre_point}->y_coord, $Y - 1 );
}

sub test_move_up {
    my $creature = &init;

    ok( $creature->move_up );
    is( $creature->point->x_coord,        $X );
    is( $creature->point->y_coord,        $Y - 1 );
    is( $creature->{_pre_point}->x_coord, $X );
    is( $creature->{_pre_point}->y_coord, $Y );
}

sub test_move_down {
    my $creature = &init;

    ok( $creature->move_down );
    is( $creature->point->x_coord,        $X );
    is( $creature->point->y_coord,        $Y + 1 );
    is( $creature->{_pre_point}->x_coord, $X );
    is( $creature->{_pre_point}->y_coord, $Y );
}

sub test_move_right {
    my $creature = &init;

    ok( $creature->move_right );
    is( $creature->point->x_coord,        $X + 1 );
    is( $creature->point->y_coord,        $Y );
    is( $creature->{_pre_point}->x_coord, $X );
    is( $creature->{_pre_point}->y_coord, $Y );
}

sub test_move_left {
    my $creature = &init;

    ok( $creature->move_left );
    is( ( $creature->point->x_coord ), $X - 1 );
    is( ( $creature->point->y_coord ), $Y );
    is( $creature->{_pre_point}->x_coord, $X );
    is( $creature->{_pre_point}->y_coord, $Y );
}

sub test_get_player_point {
    my $player_point_x = 100;
    my $player_point_y = 150;
    my $player_point   = Game::TextPacMonster::Point->new( $player_point_x, $player_point_y );

    my $map = Test::MockObject->new();
    $map->mock( 'get_player_point', sub { $player_point } );
    is( $map->get_player_point, $player_point, "PASS: mock surely create" );

    my $creature = Game::TextPacMonster::Creature->new( 12, $POINT, $map );
    my $returned_player_point = $creature->get_player_point;

    is( $returned_player_point->{x}, $player_point_x );
    is( $returned_player_point->{y}, $player_point_y );
}

sub test__move_point {

    my $id    = 12;
    my $x     = 5;
    my $y     = 8;
    my $point = Game::TextPacMonster::Point->new( $x, $y );

    my $next_x     = 6;
    my $next_y     = 7;
    my $next_point = Game::TextPacMonster::Point->new( $next_x, $next_y );

    my $map_can_move_true_mock = Test::MockObject->new();
    $map_can_move_true_mock->set_true('can_move');
    ok( $map_can_move_true_mock->can_move, "PASS: mock surely created" );

    my $creature = Game::TextPacMonster::Creature->new( $id, $point, $map_can_move_true_mock );

    ok( $creature->_move_point($next_point), "PASS: creature moved" );
    is( $creature->point, $next_point, "PASS: same point object" );
    is( $creature->point->x_coord, $next_x );
    is( $creature->point->y_coord, $next_y );

    is( $creature->pre_point, $point, "PATH: same point object" );
    is( $creature->pre_point->x_coord, $x );
    is( $creature->pre_point->y_coord, $y );

    my $map_can_move_false_mock = Test::MockObject->new();
    $map_can_move_false_mock->set_false('can_move');
    ok( !$map_can_move_false_mock->can_move, "PATH: mock surely created" );

    my $didnt_move_creature =
      Game::TextPacMonster::Creature->new( $id, $point, $map_can_move_false_mock );
    ok( !$didnt_move_creature->_move_point($next_point),
        "PATH: creature didn't move" );

    is( $didnt_move_creature->point, $point, "PATH: same point object" );
    is( $didnt_move_creature->point->x_coord, $x );
    is( $didnt_move_creature->point->y_coord, $y );

    is( $didnt_move_creature->pre_point, undef, "PATH: must be undef" );
}

sub test_stay {
    my $creature = &init;

    is( $creature->stay, 1 );
    isnt( $creature->point, $POINT, "PASS: OTHER OBJECT" );
    is( $creature->pre_point, $POINT, "PASS: SAME OBJECT" );
    is( $creature->pre_point->x_coord, $X );
    is( $creature->pre_point->y_coord, $Y );

}

sub test_pre_point {
    my $creature = &init;
    my $point = Game::TextPacMonster::Point->new( 6, 3 );

    $creature->point($point);

    is( $creature->pre_point, $POINT, "PASS: SAME POINTER" );
    is( $creature->pre_point->x_coord, $X );
    is( $creature->pre_point->y_coord, $Y );
}

sub test_point_as_setter {
    my $creature = &init;
    my $point = Game::TextPacMonster::Point->new( 6, 3 );

    $creature->point($point);

    is( $creature->point, $point, "PASS: SAME POINTER" );
    is( $creature->point->x_coord, 6 );
    is( $creature->point->y_coord, 3 );

}

sub test_point_as_getter {
    my $creature = &init;

    is( $creature->point, $POINT, "PASS: SAME POINTER" );
    is( $creature->point->x_coord, 5 );
    is( $creature->point->y_coord, 2 );
}

sub test_id {
    my $creature = &init;
    is( $creature->id, $ID );
}

sub test_new {
    my $creature = &init;
    is( ref($creature), "Game::TextPacMonster::Creature" );
}

sub init {

    my $map = Test::MockObject->new();
    $map->set_true('can_move');
    $map->set_always( 'get_time', 0 );

    my $creature = Game::TextPacMonster::Creature->new( $ID, $POINT, $map );
    return $creature;
}

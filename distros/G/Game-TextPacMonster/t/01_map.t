use strict;
use warnings;
use utf8;

use Test::More 'no_plan';


use Data::Dumper;
use Game::TextPacMonster::Map;

&test_new;
&test_get_string;
&test_is_win;
&test_count_feeds;
&test_get_current_time;
&test_increase_current_time;
&test_del_feed;
&test_get_player_point;
&test_is_lose_timeout;
&test_is_lose_switched;
&test_is_lose_at_same_point;
&test_count_movable;
&test_can_move;
&test_get_log;
&test_command_player;

sub test_command_player {
    my $map_str = <<"EOF";
###########
#.V..#..H.#
#.##.J.##.#
#L#..#..R.#
#.#.###.#.#
#....@....#
###########
EOF

    my $map = Game::TextPacMonster::Map->new(
        {
            timelimit  => 50,
            map_string => $map_str,
        }
    );



    my $feeds_num = $map->count_feeds;
    my $current_time = $map->get_current_time;

    ok(!$map->command_player);
    ok(!$map->command_player('a'));
    ok(!$map->command_player('j'));

    ok($map->command_player('l'));
    is($map->get_log, 'l');
    is($map->count_feeds, $feeds_num - 1 );
    is($map->get_current_time, $current_time + 1 );
    ok(!$map->is_win);
    ok(!$map->is_lose);

    my $map_str_after_first = <<"EOF";
###########
#V ..#.H .#
#.##J .##.#
# #..#.R .#
#L#.###.#.#
#.... @...#
###########
EOF
    chomp $map_str_after_first;
    is($map->get_string, $map_str_after_first);


    ok($map->command_player('h'));
    is($map->get_log, 'lh');
    is($map->count_feeds, $feeds_num - 1 );
    is($map->get_current_time, $current_time + 2 );

    my $map_str_after_second = <<"EOF";
###########
#. ..#H. .#
#V##. .##.#
# #.J#R. .#
#.#.###.#.#
#L...@ ...#
###########
EOF
    chomp $map_str_after_second;
    is($map->get_string, $map_str_after_second);
}



sub test_get_log {
    my $map = &init;
    is($map->get_log, q{});
    $map->{_log} .= 'l';
    is($map->get_log, 'l');
}


sub test_can_move {
    my $map_str = <<"EOF";
###########
##### #####
#####H#####
# R ..  #.#
####...####
# V..@ L .#
#####J#####
##### #####
###########
EOF
    my $map = Game::TextPacMonster::Map->new(
        {
            timelimit  => 10,
            map_string => $map_str,
        }
    );

    my $not_exists_p = Game::TextPacMonster::Point->new(100, 100);
    ok(!$map->can_move($not_exists_p));
    my $creature_p = Game::TextPacMonster::Point->new(2, 3);
    ok($map->can_move($creature_p));
    my $player_p = Game::TextPacMonster::Point->new(5, 5);
    ok($map->can_move($player_p));
    my $dot_p = Game::TextPacMonster::Point->new(4, 5);
    ok($map->can_move($dot_p));
    my $sharp_p = Game::TextPacMonster::Point->new(5, 0);
    ok(!$map->can_move($sharp_p));
}




sub test_count_movable {
    my $map_str = <<"EOF";
######################
##### ################
#####H########   #####
# R ..  #.# ### #### #
####...####  ######  #
# V..@ L .# ######## #
#####J######### ######
##### ########   #####
######################
EOF

    my $map = Game::TextPacMonster::Map->new(
        {
            timelimit  => 10,
            map_string => $map_str,
        }
    );

    my $not_movable_p = Game::TextPacMonster::Point->new(9, 3);
    is($map->count_movable_points($not_movable_p), 0);

    my $deadend_p1 = Game::TextPacMonster::Point->new(5, 1);
    is($map->count_movable_points($deadend_p1), 1);

    my $deadend_p2 = Game::TextPacMonster::Point->new(5, 7);
    is($map->count_movable_points($deadend_p2), 1);

    my $deadend_p3 = Game::TextPacMonster::Point->new(1, 5);
    is($map->count_movable_points($deadend_p3), 1);

    my $deadend_p4 = Game::TextPacMonster::Point->new(9, 5);
    is($map->count_movable_points($deadend_p4), 1);


    my $two_way_p1 = Game::TextPacMonster::Point->new(2, 4);
    is($map->count_movable_points($two_way_p1), 2);

    my $two_way_p2 = Game::TextPacMonster::Point->new(5, 2);
    is($map->count_movable_points($two_way_p2), 2);



    my $three_way_p1 = Game::TextPacMonster::Point->new(15, 2);
    is($map->count_movable_points($three_way_p1), 3);

    my $three_way_p2 = Game::TextPacMonster::Point->new(20, 4);
    is($map->count_movable_points($three_way_p2), 3);

    my $three_way_p3 = Game::TextPacMonster::Point->new(15, 7);
    is($map->count_movable_points($three_way_p3), 3);

    my $three_way_p4 = Game::TextPacMonster::Point->new(11, 4);
    is($map->count_movable_points($three_way_p4), 3);


    my $four_way_p = Game::TextPacMonster::Point->new(5, 4);
    is($map->count_movable_points($four_way_p), 4);
}


sub test_get_left_time {
    my $map = &init;

    is($map->get_left_time, 50);

    $map->{_current_time} += 1;

    is($map->get_left_time, 49);
}


sub test_get_player_point {
    my $map = &init;
    is( $map->get_player_point->x_coord, 5 );
    is( $map->get_player_point->y_coord, 5 );
}

sub init {
    my $map_str = <<"EOF";
###########
#.V..#..H.#
#.##...##.#
#L#..#..R.#
#.#.###.#.#
#....@....#
###########
EOF

    my $map = Game::TextPacMonster::Map->new(
        {
            timelimit  => 50,
            map_string => $map_str,
        }
    );

    return $map;
}

sub test_new {
    my $map = &init;
    isa_ok( $map, 'Game::TextPacMonster::Map' );

}

sub test_get_string {

    my $map     = &init;
    my $map_str = <<'EOF';
###########
#.V..#..H.#
#.##...##.#
#L#..#..R.#
#.#.###.#.#
#....@....#
###########
EOF
    chomp $map_str;
    is( $map->get_string, $map_str, "PASS: get_string" );
}

sub test_count_feeds {
    my $initial_feeds_num = 28;

    my $map = &init;

    is( $map->count_feeds, $initial_feeds_num, "PASS: count_feeds" );

}

sub test_del_feed {
    my $initial_feeds_num = 28;
    my $map               = &init;

    $map->del_feed( Game::TextPacMonster::Point->new( 9, 5 ) );
    is( $map->count_feeds, $initial_feeds_num - 1 );
    my $map_str = <<"EOF";
###########
#.V..#..H.#
#.##...##.#
#L#..#..R.#
#.#.###.#.#
#....@... #
###########
EOF
    chomp $map_str;
    is( $map->get_string, $map_str );
}

sub test_get_current_time {
    my $map = &init;
    is( $map->get_current_time, 0 );
}

sub test_increase_current_time {
    my $map = &init;
    $map->increase_current_time;
    is( $map->get_current_time, 1 );
}

sub test_is_win {
    my $map_str = <<"EOF";
###########
# V  #  H #
# ##   ## #
#L#  #  R #
# # ### # #
#    @   .#
###########
EOF

    my $map = Game::TextPacMonster::Map->new(
        {
            timelimit  => 1,
            map_string => $map_str,
        }
    );

    # not finished to eat feeds
    is( $map->is_win, 0, "PASS: not win." );

    # finished to eat feeds in time.
    $map->del_feed( Game::TextPacMonster::Point->new( 9, 5 ) );
    is( $map->count_feeds, 0 );
    is( $map->is_win, 1, "PASS: win." );

    # finished to eat feeds but time is orver
    $map->increase_current_time;
    is( $map->is_win, 1, "PASS: win." );
    $map->increase_current_time;
    is( $map->is_win, 0, "PASS: not win." );
}

sub test_is_lose_timeout {
    my $map_str = << 'EOF';
##########
#. R @   #
##########
EOF

    my $player_id = '1';
    my $timelimit = 10;

    my $map = Game::TextPacMonster::Map->new(
        {
            'timelimit'  => $timelimit,
            'map_string' => $map_str
        }
    );

    $map->{_current_time} = $timelimit - 1;
    ok( !$map->is_lose, 'test_is_lose' );

    $map->{_current_time} = $timelimit;
    ok( $map->is_lose, 'test_is_lose' );

    $map->{_current_time} = $timelimit + 1;
    ok( $map->is_lose, 'test_is_lose' );
}

sub test_is_lose_switched {
    my $map_str = << 'EOF';
##########
#. R @   #
##########
EOF

    my $player_id = '1';
    my $timelimit = 10;

    my $map = Game::TextPacMonster::Map->new(
        {
            'timelimit'  => $timelimit,
            'map_string' => $map_str
        }
    );

    my $player_ref = $map->{_objects}->{1};
    my $enemy_ref  = $map->{_objects}->{ $player_id + 1 };

    $player_ref->{_pre_point} = Game::TextPacMonster::Point->new( 1, 8 );
    $player_ref->{_point}     = Game::TextPacMonster::Point->new( 1, 7 );

    $enemy_ref->{_pre_point} = Game::TextPacMonster::Point->new( 1, 1 );
    $enemy_ref->{_point}     = Game::TextPacMonster::Point->new( 1, 2 );

    ok( !$map->is_lose, 'test_is_lose_switched' );  # not switched so don't lose

    $player_ref->{_pre_point} = Game::TextPacMonster::Point->new( 1, 5 );
    $player_ref->{_point}     = Game::TextPacMonster::Point->new( 1, 6 );

    $enemy_ref->{_pre_point} = Game::TextPacMonster::Point->new( 1, 6 );
    $enemy_ref->{_point}     = Game::TextPacMonster::Point->new( 1, 5 );

    ok( $map->is_lose, 'test_is_lose_switched' );    # switched so lose
}

sub test_is_lose_at_same_point
{
    my $map_str = << 'EOF';
##########
#. R @   #
##########
EOF

    my $player_id = '1';
    my $timelimit = 10;

    my $map = Game::TextPacMonster::Map->new(
        {
            'timelimit'  => $timelimit,
            'map_string' => $map_str
        }
    );

    my $player_ref = $map->{_objects}->{1};
    my $enemy_ref  = $map->{_objects}->{ $player_id + 1 };

    $player_ref->{_pre_point} = Game::TextPacMonster::Point->new( 1, 8 );
    $player_ref->{_point}     = Game::TextPacMonster::Point->new( 1, 7 );

    $enemy_ref->{_pre_point} = Game::TextPacMonster::Point->new( 1, 1 );
    $enemy_ref->{_point}     = Game::TextPacMonster::Point->new( 1, 2 );

    ok( !$map->is_lose, 'test_is_lose_same_point' ); # not same point

    $enemy_ref->{_point} = Game::TextPacMonster::Point->new( 1, 7 );

    ok( $map->is_lose, 'test_is_lose_same_point' ); # same point so lose

}


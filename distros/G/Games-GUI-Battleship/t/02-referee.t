#!/usr/bin/env perl

use v5.38;
use experimental 'signatures';
use Test2::V0;

use lib 'lib';
use lib '../lib';
use Games::GUI::Battleship::Ship;
use Games::GUI::Battleship::Board;

subtest 'Referee hit, miss, and sunk mechanics' => sub {
    my $board = Games::GUI::Battleship::Board->new;

    my $destroyer = Games::GUI::Battleship::Ship->new(
        type => 'Destroyer',
        x    => 4,
        y    => 5,
        dir  => 'H',
    );
    $board->place_ship($destroyer);

    # Miss
    my $res1 = $board->receive_shot( 1, 1 );
    is( $res1->{result}, 'miss', 'shot at empty cell (1, 1) is a miss' );
    ok( $board->has_shot( 1, 1 ), 'cell (1, 1) has been shot' );
    is( $board->shot_at( 1, 1 ), 'M', 'shot marker is M' );

    # Duplicate shot
    my $dup = $board->receive_shot( 1, 1 );
    is( $dup, undef, 'duplicate shot returns undef' );

    # Hit 1 (damage, not sunk)
    my $res2 = $board->receive_shot( 4, 5 );
    is( $res2->{result},         'hit',       'shot at (4, 5) is a hit' );
    is( $res2->{ship}->type,     'Destroyer', 'hit Destroyer' );
    is( $board->shot_at( 4, 5 ), 'H',         'shot marker is H' );
    ok( !$board->all_sunk, 'fleet not all sunk' );
    is( $board->ships_remaining, 1, '1 ship remaining' );

    # Hit 2 (sunk)
    my $res3 = $board->receive_shot( 5, 5 );
    is( $res3->{result}, 'sunk', 'shot at (5, 5) sinks the Destroyer' );
    is( $board->shot_at( 4, 5 ), 'S', 'first cell updated to S' );
    is( $board->shot_at( 5, 5 ), 'S', 'second cell updated to S' );

    ok( $board->all_sunk, 'all ships are sunk' );
    is( $board->ships_remaining, 0, '0 ships remaining' );
    is( $board->ships_sunk,      1, '1 ship sunk' );
};

done_testing;
1;


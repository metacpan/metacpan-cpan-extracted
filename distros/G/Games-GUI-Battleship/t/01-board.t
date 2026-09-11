#!/usr/bin/env perl

use v5.38;
use experimental 'signatures';
use Test2::V0;

use lib 'lib';
use lib '../lib';
use Games::GUI::Battleship::Ship;
use Games::GUI::Battleship::Board;

subtest 'Ship model fundamentals' => sub {
    my $ship = Games::GUI::Battleship::Ship->new(
        type => 'Battleship',
        x    => 2,
        y    => 3,
        dir  => 'H',
    );

    is( $ship->type,   'Battleship', 'type is correct' );
    is( $ship->length, 4,            'length is 4 for Battleship' );
    is( $ship->x,      2,            'x is 2' );
    is( $ship->y,      3,            'y is 3' );
    is( $ship->dir,    'H',          'dir is H' );

    my @coords = $ship->coordinates;
    is(
        \@coords,
        [ [ 2, 3 ], [ 3, 3 ], [ 4, 3 ], [ 5, 3 ] ],
        'horizontal coordinates computed properly'
    );

    ok( $ship->occupies( 3,  3 ), 'occupies (3, 3)' );
    ok( !$ship->occupies( 1, 3 ), 'does not occupy (1, 3)' );
    ok( !$ship->occupies( 6, 3 ), 'does not occupy (6, 3)' );

    # Rotate
    is( $ship->rotate, 'V', 'rotated to vertical' );
    my @v_coords = $ship->coordinates;
    is(
        \@v_coords,
        [ [ 2, 3 ], [ 2, 4 ], [ 2, 5 ], [ 2, 6 ] ],
        'vertical coordinates computed properly'
    );

    # Damage & sinking
    ok( !$ship->is_sunk, 'not sunk initially' );
    is( $ship->hit_count, 0, '0 hits' );

    ok( $ship->record_hit( 2, 3 ), 'hit at (2, 3)' );
    is( $ship->hit_count, 1, '1 hit' );
    ok( !$ship->is_sunk, 'still not sunk' );

    ok( !$ship->record_hit( 9, 9 ), 'shot off-target not recorded' );
    is( $ship->hit_count, 1, 'still 1 hit' );

    $ship->record_hit( 2, 4 );
    $ship->record_hit( 2, 5 );
    $ship->record_hit( 2, 6 );

    is( $ship->hit_count, 4, '4 hits' );
    ok( $ship->is_sunk, 'ship is now sunk!' );
};

subtest 'Board placement and collision detection' => sub {
    my $board = Games::GUI::Battleship::Board->new( size => 10 );
    is( $board->size, 10, 'board size is 10' );

    # Valid placement
    my $carrier = Games::GUI::Battleship::Ship->new(
        type => 'Carrier',
        x    => 1,
        y    => 1,
        dir  => 'H',
    );
    ok( $board->can_place_ship($carrier), 'can place carrier at (1, 1) H' );
    $board->place_ship($carrier);
    is( scalar( $board->ships ), 1, '1 ship placed' );

    # Out of bounds placement
    my $bad_bounds = Games::GUI::Battleship::Ship->new(
        type => 'Battleship',
        x    => 8,
        y    => 1,
        dir  => 'H',
    );
    ok( !$board->can_place_ship($bad_bounds),
        'cannot place battleship at (8, 1) H (extends to col 11)' );

    # Collision with existing ship
    my $colliding = Games::GUI::Battleship::Ship->new(
        type => 'Destroyer',
        x    => 3,
        y    => 1,
        dir  => 'V',
    );
    ok( !$board->can_place_ship($colliding),
        'cannot place destroyer overlapping carrier at (3, 1)' );

    # Place second ship in clear waters
    my $cruiser = Games::GUI::Battleship::Ship->new(
        type => 'Cruiser',
        x    => 3,
        y    => 2,
        dir  => 'V',
    );
    ok( $board->can_place_ship($cruiser), 'can place cruiser at (3, 2) V' );
    $board->place_ship($cruiser);
    is( scalar( $board->ships ), 2, '2 ships placed' );
};

subtest 'Board random fleet placement' => sub {
    my $board = Games::GUI::Battleship::Board->new;
    ok( $board->place_random_fleet, 'place_random_fleet succeeds' );
    is( scalar( $board->ships ), 5, 'all 5 fleet ships are placed' );

    # Verify no overlaps
    my %occupied;
    for my $ship ( $board->ships ) {
        for my $coord ( $ship->coordinates ) {
            my $k = "$coord->[0],$coord->[1]";
            ok( !$occupied{$k},
                "cell $k is uniquely occupied by " . $ship->type );
            $occupied{$k} = $ship->type;
        }
    }
};

subtest 'Shot tracking, counts, and accuracy statistics' => sub {
    my $board = Games::GUI::Battleship::Board->new;
    my $ship  = Games::GUI::Battleship::Ship->new(
        type => 'Destroyer',
        x    => 2,
        y    => 2,
        dir  => 'H',
    );
    $board->place_ship($ship);

    # Initial state
    is( $board->total_shots,   0,   'initially 0 total shots' );
    is( $board->hit_count,     0,   'initially 0 hits' );
    is( $board->miss_count,    0,   'initially 0 misses' );
    is( $board->shot_accuracy, 0.0, 'initially 0.0% accuracy' );

    # Miss shot at (1, 1)
    $board->receive_shot( 1, 1 );
    is( $board->total_shots,   1,   '1 total shot' );
    is( $board->hit_count,     0,   '0 hits' );
    is( $board->miss_count,    1,   '1 miss' );
    is( $board->shot_accuracy, 0.0, '0.0% accuracy after 1 miss' );

    # Hit shot at (2, 2)
    $board->receive_shot( 2, 2 );
    is( $board->total_shots,   2,    '2 total shots' );
    is( $board->hit_count,     1,    '1 hit' );
    is( $board->miss_count,    1,    '1 miss' );
    is( $board->shot_accuracy, 50.0, '50.0% accuracy after 1 hit and 1 miss' );

    # Sunk hit at (3, 2)
    $board->receive_shot( 3, 2 );
    is( $board->total_shots, 3, '3 total shots' );
    is( $board->hit_count,   2, '2 hits (including sunk)' );
    is( $board->miss_count,  1, '1 miss' );
    ok(
        abs( $board->shot_accuracy - ( 2 / 3 * 100 ) ) < 0.01,
        '66.67% accuracy after 2 hits and 1 miss'
    );

    # Reset shots
    $board->reset_shots;
    is( $board->total_shots,   0,   '0 shots after reset' );
    is( $board->hit_count,     0,   '0 hits after reset' );
    is( $board->miss_count,    0,   '0 misses after reset' );
    is( $board->shot_accuracy, 0.0, '0.0% accuracy after reset' );
};

done_testing;
1;


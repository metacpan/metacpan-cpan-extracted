#!/usr/bin/env perl

use v5.38;
use experimental 'signatures';
use Test2::V0;

use lib 'lib';
use lib '../lib';

use Games::GUI::Battleship::AI;
use Games::GUI::Battleship::Ship;

subtest 'AI Factory creation' => sub {
    my $easy = Games::GUI::Battleship::AI->create('easy');
    is( $easy->name,       'NaiveAI', 'easy creates NaiveAI' );
    is( $easy->difficulty, 'easy',    'difficulty is easy' );

    my $normal = Games::GUI::Battleship::AI->create('normal');
    is( $normal->name,       'ParityAI', 'normal creates ParityAI' );
    is( $normal->difficulty, 'normal',   'difficulty is normal' );

    my $hard = Games::GUI::Battleship::AI->create('hard');
    is( $hard->name,       'ProbabilityAI', 'hard creates ProbabilityAI' );
    is( $hard->difficulty, 'hard',          'difficulty is hard' );
};

subtest 'Naive AI targeting and hit response' => sub {
    my $ai = Games::GUI::Battleship::AI->create('easy');

    my ( $x1, $y1, $mode1 ) = $ai->select_target;
    ok( defined $x1 && defined $y1, "NaiveAI selected ($x1, $y1)" );
    is( $mode1, 'Linear Sequential Scan', 'first shot is sequential scan' );

    # Record miss
    $ai->record_result( x => $x1, y => $y1, result => 'miss' );
    ok( $ai->has_shot( $x1, $y1 ), "shot ($x1, $y1) is recorded" );

    # Next target should be different
    my ( $x2, $y2, $mode2 ) = $ai->select_target;
    ok( !( $x2 == $x1 && $y2 == $y1 ), "second shot is distinct" );

    # Simulate a hit at (5, 5)
    $ai->record_result( x => 5, y => 5, result => 'hit' );
    my ( $x3, $y3, $mode3 ) = $ai->select_target;
    is(
        $mode3,
        'Basic Adjacent Probe',
        'target mode changes to probe after hit'
    );

    # The probed target should be adjacent to (5, 5)
    my $dist = abs( $x3 - 5 ) + abs( $y3 - 5 );
    is( $dist, 1, "probed target ($x3, $y3) is adjacent to (5, 5)" );
};

subtest 'Parity AI checkerboard hunt and line extension' => sub {
    my $ai = Games::GUI::Battleship::AI->create('normal');

    my ( $x1, $y1, $mode1 ) = $ai->select_target;
    ok( defined $x1 && defined $y1, "ParityAI selected ($x1, $y1)" );
    is(
        $mode1,
        'Checkerboard Parity Hunt',
        'initial hunt uses checkerboard parity'
    );
    is( ( $x1 + $y1 ) % 2, 0, 'parity property (x + y) % 2 == 0 holds' );

    # Simulate two adjacent hits at (4, 4) and (5, 4)
    $ai->record_result( x => 4, y => 4, result => 'hit' );
    $ai->record_result( x => 5, y => 4, result => 'hit' );

    my ( $x2, $y2, $mode2 ) = $ai->select_target;
    is(
        $mode2,
        'Line Extension (Horizontal)',
        'two horizontal hits trigger horizontal line extension'
    );

    # Endpoint should be either (3, 4) or (6, 4)
    is( $y2, 4, 'y coordinate stays aligned on row 4' );
    ok( $x2 == 3 || $x2 == 6, 'x coordinate is at a line endpoint (3 or 6)' );

    # Simulate sinking the ship
    my $destroyer = Games::GUI::Battleship::Ship->new(
        type => 'Destroyer',
        x    => 4,
        y    => 4,
        dir  => 'H',
    );
    $destroyer->record_hit( 4, 4 );
    $destroyer->record_hit( 5, 4 );

    $ai->record_result(
        x      => 5,
        y      => 4,
        result => 'sunk',
        ship   => $destroyer,
    );

# After sinking, the AI should return to hunt mode or probe remaining un-sunk hits
    my ( $x3, $y3, $mode3 ) = $ai->select_target;
    is(
        $mode3,
        'Checkerboard Parity Hunt',
        'returns to parity hunt when all hits are sunk'
    );
};

subtest 'Parity AI randomized search distribution across board' => sub {

    # 1. Independent instances do not all start deterministically at (1, 1)
    my %start_coords;
    for ( 1 .. 20 ) {
        my $ai = Games::GUI::Battleship::AI->create('normal');
        my ( $x, $y, $mode ) = $ai->select_target;
        is( $mode, 'Checkerboard Parity Hunt', 'mode is parity hunt' );
        is( ( $x + $y ) % 2, 0,                "parity holds for ($x, $y)" );
        $start_coords{"$x,$y"}++;
    }
    cmp_ok( scalar keys %start_coords,
        '>', 1,
        'initial hunt target is randomized across multiple coordinates' );

    # 2. Sequential hunt shots span multiple rows and columns
    my $ai = Games::GUI::Battleship::AI->create('normal');
    my %rows;
    my %cols;
    for ( 1 .. 15 ) {
        my ( $x, $y, $mode ) = $ai->select_target;
        $rows{$y}++;
        $cols{$x}++;
        $ai->record_result( x => $x, y => $y, result => 'miss' );
    }
    cmp_ok( scalar keys %rows,
        '>=', 3, 'hunt shots span at least 3 distinct rows' );
    cmp_ok( scalar keys %cols,
        '>=', 3, 'hunt shots span at least 3 distinct columns' );

    # 3. Orthogonal probes around hit are distributed
    my $probe_ai = Games::GUI::Battleship::AI->create('normal');
    $probe_ai->record_result( x => 5, y => 5, result => 'hit' );
    my %probes;
    for ( 1 .. 30 ) {
        my ( $px, $py, $pmode ) = $probe_ai->select_target;
        is( $pmode, 'Orthogonal Target Probe', 'probe mode active' );
        $probes{"$px,$py"}++;
    }
    cmp_ok( scalar keys %probes,
        '>', 1, 'orthogonal probe direction is randomized across neighbors' );
};

subtest 'Probability AI (Hard) hunt, target heatmap, and line extension' =>
  sub {
    my $ai = Games::GUI::Battleship::AI->create('hard');
    is( $ai->name,       'ProbabilityAI', 'name is ProbabilityAI' );
    is( $ai->difficulty, 'hard',          'difficulty is hard' );

    # Initial hunt target
    my ( $x1, $y1, $mode1 ) = $ai->select_target;
    ok( defined $x1 && defined $y1, "initial target is defined ($x1, $y1)" );
    is( $mode1, 'Probability Density Hunt',
        'mode is Probability Density Hunt' );
    ok( $x1 >= 1 && $x1 <= 10 && $y1 >= 1 && $y1 <= 10,
        'coordinates within board' );

    # Center-bias check: initial target is in high-density central zone (3..8)
    ok( $x1 >= 3 && $x1 <= 8, 'x coordinate is in central high-density area' );
    ok( $y1 >= 3 && $y1 <= 8, 'y coordinate is in central high-density area' );

    # Simulate hit at (5, 5)
    $ai->record_result( x => 5, y => 5, result => 'hit' );
    my ( $x2, $y2, $mode2 ) = $ai->select_target;
    is(
        $mode2,
        'Target Heatmap (Orthogonal Focus)',
        'switches to orthogonal focus after 1st hit'
    );
    my $dist = abs( $x2 - 5 ) + abs( $y2 - 5 );
    is( $dist, 1, "target ($x2, $y2) is orthogonal neighbor to (5, 5)" );

    # Simulate second hit at (6, 5)
    $ai->record_result( x => 6, y => 5, result => 'hit' );
    my ( $x3, $y3, $mode3 ) = $ai->select_target;
    is(
        $mode3,
        'Target Heatmap (Line Extension)',
        'switches to line extension after 2 collinear hits'
    );
    is( $y3, 5, 'y coordinate remains aligned with row 5' );
    ok( $x3 == 4 || $x3 == 7,
        "x coordinate is line endpoint (4 or 7), got $x3" );

    # Sinking Destroyer at (5, 5) and (6, 5)
    my $destroyer = Games::GUI::Battleship::Ship->new(
        type => 'Destroyer',
        x    => 5,
        y    => 5,
        dir  => 'H',
    );
    $destroyer->record_hit( 5, 5 );
    $destroyer->record_hit( 6, 5 );

    $ai->record_result(
        x      => 6,
        y      => 5,
        result => 'sunk',
        ship   => $destroyer,
    );

    # After sinking, returns to hunt mode with updated surviving ships
    my ( $x4, $y4, $mode4 ) = $ai->select_target;
    is(
        $mode4,
        'Probability Density Hunt',
        'returns to hunt mode after sinking ship'
    );
    ok(
        !exists $ai->{surviving_ships}{Destroyer},
        'Destroyer removed from surviving ships'
    );
    ok(
        exists $ai->{surviving_ships}{Carrier},
        'Carrier remains in surviving ships'
    );
  };

done_testing;
1;


#!/usr/bin/env perl

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Test2::V0;

use lib 'lib';
use lib '../lib';

use Prima;
use Prima::Application;
use Games::GUI::Battleship;

subtest 'Game initialization and placement phase' => sub {
    my $app = Games::GUI::Battleship->new( difficulty => 'easy' );
    is( $app->{phase},         'placement', 'starts in placement phase' );
    is( $app->{difficulty},    'easy',      'difficulty is easy' );
    is( $app->{placement_idx}, 0,           'placement index is 0' );
    is( $app->{placement_dir}, 'H',         'default direction is H' );

    $app->rotate_placement_ship;
    is( $app->{placement_dir}, 'V', 'rotated to V' );
    $app->rotate_placement_ship;
    is( $app->{placement_dir}, 'H', 'rotated back to H' );

    $app->randomize_player_fleet;
    is( $app->{phase}, 'battle', 'randomize transitions to battle' );
    is( $app->{player_board}->ship_count,   5, '5 player ships placed' );
    is( $app->{opponent_board}->ship_count, 5, '5 opponent ships placed' );
};

subtest 'Battle click handling and timer lifecycle' => sub {
    my $app = Games::GUI::Battleship->new( difficulty => 'easy' );
    my $win = $app->create_window;
    $win->hide;

    $app->randomize_player_fleet;
    is( $app->{phase}, 'battle', 'in battle phase' );

    # AI timer should be inactive initially
    ok( defined $app->{ai_timer},      'ai_timer exists' );
    ok( !$app->{ai_timer}->get_active, 'ai_timer is not active initially' );

    # Player fires at (1, 1)
    $app->handle_battle_click( 1, 1 );
    ok(
        $app->{opponent_board}->has_shot( 1, 1 ),
        'opponent board received shot at (1, 1)'
    );
    ok( $app->{ai_timer}->get_active, 'ai_timer started after player shot' );

    # Second shot while timer is running should be blocked
    $app->handle_battle_click( 2, 2 );
    ok(
        !$app->{opponent_board}->has_shot( 2, 2 ),
        'shot at (2, 2) blocked while AI timer active'
    );

    # Trigger AI turn and stop timer
    $app->{ai_timer}->stop;
    $app->process_ai_turn;
    ok( !$app->{ai_timer}->get_active, 'ai_timer stopped after AI turn' );

    # Check that AI fired on player board
    my $player_shots = 0;
    for my $r ( 1 .. 10 ) {
        for my $c ( 1 .. 10 ) {
            $player_shots++ if $app->{player_board}->has_shot( $c, $r );
        }
    }
    is( $player_shots, 1, 'AI fired exactly 1 shot on player board' );

    # Next player shot at (2, 2) should now be accepted
    $app->handle_battle_click( 2, 2 );
    ok( $app->{opponent_board}->has_shot( 2, 2 ),
        'shot at (2, 2) accepted now' );
    $app->{ai_timer}->stop;

    # Reset fleet stops timer and resets state
    $app->reset_placement;
    is( $app->{phase}, 'placement',
        'reset_placement returns to placement phase' );
    ok( !$app->{ai_timer}->get_active, 'timer stopped on reset' );

    $win->destroy;
};

subtest 'Keyboard firing in battle phase' => sub {
    my $app = Games::GUI::Battleship->new( difficulty => 'normal' );
    my $win = $app->create_window;
    $win->hide;

    $app->randomize_player_fleet;
    is( $app->{phase}, 'battle', 'in battle phase' );

    # Set hover coordinates
    $app->{hover_opp_col} = 4;
    $app->{hover_opp_row} = 7;

    # Trigger Space key
    $win->notify( 'KeyDown', ord(' '), kb::Space, 0 );

    ok(
        $app->{opponent_board}->has_shot( 4, 7 ),
        'space key fired at hovered cell (4, 7)'
    );
    $app->{ai_timer}->stop;

    $win->destroy;
};

subtest 'Hit and sunk status message formatting' => sub {
    my $app = Games::GUI::Battleship->new( difficulty => 'easy' );
    my $win = $app->create_window;
    $win->hide;

    $app->{phase} = 'battle';
    $app->{player_board}->clear_ships->reset_shots;
    $app->{opponent_board}->clear_ships->reset_shots;

    my $opp_destroyer = Games::GUI::Battleship::Ship->new(
        type => 'Destroyer',
        x    => 1,
        y    => 1,
        dir  => 'H',
    );
    my $opp_cruiser = Games::GUI::Battleship::Ship->new(
        type => 'Cruiser',
        x    => 1,
        y    => 3,
        dir  => 'H',
    );
    $app->{opponent_board}->place_ship($opp_destroyer);
    $app->{opponent_board}->place_ship($opp_cruiser);

    my $player_destroyer = Games::GUI::Battleship::Ship->new(
        type => 'Destroyer',
        x    => 5,
        y    => 5,
        dir  => 'H',
    );
    my $player_cruiser = Games::GUI::Battleship::Ship->new(
        type => 'Cruiser',
        x    => 5,
        y    => 7,
        dir  => 'H',
    );
    $app->{player_board}->place_ship($player_destroyer);
    $app->{player_board}->place_ship($player_cruiser);

    # Player hits opponent Destroyer at (1, 1)
    $app->handle_battle_click( 1, 1 );
    is(
        $app->{status_msg},
        'DIRECT HIT! You struck the Enemy Destroyer at A1!',
        'player hit message displays ship name properly'
    );
    unlike( $app->{status_msg}, qr/HASH\(/x,
        'no object stringification in player hit message' );
    unlike( $app->{status_msg}, qr/->type/x,
        'no literal ->type in player hit message' );
    $app->{ai_timer}->stop;

    # Player sinks opponent Destroyer at (2, 1)
    $app->handle_battle_click( 2, 1 );
    is(
        $app->{status_msg},
        'You SUNK the Enemy Destroyer at B1!',
        'player sunk message displays ship name properly'
    );
    unlike( $app->{status_msg}, qr/HASH\(/x,
        'no object stringification in player sunk message' );
    unlike( $app->{status_msg}, qr/->type/x,
        'no literal ->type in player sunk message' );
    $app->{ai_timer}->stop;

    # AI Turn: reset phase to battle so process_ai_turn runs
    $app->{phase} = 'battle';

    # Direct AI to strike player Destroyer at (5, 5)
    # Mock AI select_target to return (5, 5)
    my $orig_select = \&Games::GUI::Battleship::AI::Naive::select_target;
    no warnings 'redefine';
    local *Games::GUI::Battleship::AI::Naive::select_target = sub {
        return ( 5, 5, 'Tactical Probe' );
    };

    $app->process_ai_turn;
    is(
        $app->{status_msg},
        'WARNING! Enemy hit your Destroyer at E5! (Tactical Probe)',
        'AI hit message displays player ship name properly'
    );
    unlike( $app->{status_msg}, qr/HASH\(/x,
        'no object stringification in AI hit message' );
    unlike( $app->{status_msg}, qr/->type/x,
        'no literal ->type in AI hit message' );

    # Next AI shot sinks Destroyer at (6, 5)
    local *Games::GUI::Battleship::AI::Naive::select_target = sub {
        return ( 6, 5, 'Tactical Probe' );
    };
    $app->process_ai_turn;
    is(
        $app->{status_msg},
        'CRITICAL HIT! Enemy SUNK your Destroyer at F5! (Tactical Probe)',
        'AI sunk message displays player ship name properly'
    );
    unlike( $app->{status_msg}, qr/HASH\(/x,
        'no object stringification in AI sunk message' );
    unlike( $app->{status_msg}, qr/->type/x,
        'no literal ->type in AI sunk message' );

    $win->destroy;
};

subtest 'Randomize fleet mid-game confirmation and restart' => sub {
    my $app = Games::GUI::Battleship->new( difficulty => 'easy' );
    my $win = $app->create_window;
    $win->hide;

    $app->randomize_player_fleet;
    is( $app->{phase}, 'battle', 'started battle' );

    # Fire a shot so the boards have recorded shots
    $app->handle_battle_click( 3, 3 );
    ok( $app->{opponent_board}->has_shot( 3, 3 ), 'opponent board has shot' );

    my $dialog_called = 0;
    my $mock_return   = mb::No;

    no warnings 'redefine';
    local *Prima::MsgBox::message_box = sub ( $title, $text, $buttons ) {
        $dialog_called++;
        is( $title, 'Restart Game?', 'dialog title is Restart Game?' );
        is(
            $text,
            'Are you sure? This will restart the game.',
            'dialog text asks for confirmation'
        );
        return $mock_return;
    };

    # 1. User cancels (clicks No)
    $mock_return   = mb::No;
    $dialog_called = 0;
    $app->randomize_player_fleet;

    is( $dialog_called, 1, 'dialog was shown when randomized mid-battle' );
    is( $app->{phase},  'battle', 'phase remains battle on cancel' );
    ok(
        $app->{opponent_board}->has_shot( 3, 3 ),
        'existing shot preserved on cancel'
    );

    # 2. User confirms (clicks Yes)
    $mock_return   = mb::Yes;
    $dialog_called = 0;
    $app->randomize_player_fleet;

    is( $dialog_called, 1,        'dialog was shown again' );
    is( $app->{phase},  'battle', 'phase is battle after restart' );
    ok(
        !$app->{opponent_board}->has_shot( 3, 3 ),
        'opponent board shots reset on confirmed restart'
    );
    is( $app->{player_board}->ship_count,   5, '5 player ships placed' );
    is( $app->{opponent_board}->ship_count, 5, '5 opponent ships placed' );
    ok( defined $app->{ai}, 'fresh AI initialized' );

    # 3. Force bypasses dialog
    $dialog_called = 0;
    $app->randomize_player_fleet(1);
    is( $dialog_called, 0,        'dialog not shown when force=1' );
    is( $app->{phase},  'battle', 'battle phase after forced restart' );

    $win->destroy;
};

subtest 'Hard difficulty game initialization and combat flow' => sub {
    my $app = Games::GUI::Battleship->new( difficulty => 'hard' );
    is( $app->{difficulty},     'hard',          'app difficulty is hard' );
    is( $app->{ai}->name,       'ProbabilityAI', 'app AI is ProbabilityAI' );
    is( $app->{ai}->difficulty, 'hard',          'app AI difficulty is hard' );

    my $win = $app->create_window;
    $win->hide;

    $app->randomize_player_fleet;
    is( $app->{phase}, 'battle', 'transitioned to battle phase' );

    # Player fires at (5, 5)
    $app->handle_battle_click( 5, 5 );
    ok( $app->{opponent_board}->has_shot( 5, 5 ), 'player fired at (5, 5)' );
    ok( $app->{ai_timer}->get_active,             'AI timer active' );

    # Process AI turn
    $app->{ai_timer}->stop;
    $app->process_ai_turn;
    ok( !$app->{ai_timer}->get_active, 'AI timer stopped after AI turn' );

    # Verify AI shot was recorded on player board
    my $player_shots = 0;
    for my $r ( 1 .. 10 ) {
        for my $c ( 1 .. 10 ) {
            $player_shots++ if $app->{player_board}->has_shot( $c, $r );
        }
    }
    is( $player_shots, 1, 'Probability AI fired 1 shot on player board' );
    is( $app->{ai}->stats->{shots}, 1, 'AI stats recorded 1 shot' );

    $win->destroy;
};

done_testing;
1;


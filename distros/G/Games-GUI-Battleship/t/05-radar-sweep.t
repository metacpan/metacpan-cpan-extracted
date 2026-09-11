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
use Cairo;
use Games::GUI::Battleship;
use Games::GUI::Battleship::Renderer;
use Games::GUI::Battleship::Ship;

subtest 'Radar sweep initial state and defaults' => sub {
    my $app = Games::GUI::Battleship->new;
    is( $app->{radar_sweep_enabled}, 1,      'radar sweep enabled by default' );
    is( $app->{radar_sweep_speed}, 'normal', 'default speed is normal' );
    is( $app->{sweep_progress},    0.0,      'initial sweep progress is 0.0' );
};

subtest 'Radar sweep progress and speed adjustment' => sub {
    my $app = Games::GUI::Battleship->new;

    # Advance sweep with default / measured tick
    $app->advance_sweep;
    ok( $app->{sweep_progress} > 0.0, 'progress advances after tick' );

    # Progress wraps around at 1.0
    $app->{sweep_progress} = 0.99;
    $app->advance_sweep(0.1)
      ;    # 0.1s / 4.5s = ~0.022 progress -> 1.012 -> wraps to 0.012
    ok( $app->{sweep_progress} >= 0.0 && $app->{sweep_progress} < 0.5,
        'progress wraps back around modulo 1.0' );

    # Speed settings
    $app->set_sweep_speed('fast');
    is( $app->{radar_sweep_speed}, 'fast', 'speed set to fast' );

    $app->set_sweep_speed('slow');
    is( $app->{radar_sweep_speed}, 'slow', 'speed set to slow' );

    # Unknown speed should be ignored
    $app->set_sweep_speed('ludicrous');
    is( $app->{radar_sweep_speed}, 'slow', 'unknown speed ignored' );
};

subtest 'Radar sweep enable/disable toggle' => sub {
    my $app = Games::GUI::Battleship->new;

    $app->set_sweep_enabled(0);
    is( $app->{radar_sweep_enabled}, 0, 'radar sweep disabled' );

    my $prog_before = $app->{sweep_progress};
    $app->advance_sweep;
    is( $app->{sweep_progress},
        $prog_before, 'sweep progress does not advance when disabled' );

    $app->set_sweep_enabled(1);
    is( $app->{radar_sweep_enabled}, 1, 'radar sweep re-enabled' );
};

subtest 'Window timer lifecycle and menu synchronization' => sub {
    my $app = Games::GUI::Battleship->new;
    my $win = $app->create_window;
    $win->hide;

    ok( defined $app->{sweep_timer}, 'sweep_timer created' );
    ok(
        $app->{sweep_timer}->get_active,
        'sweep_timer active when sweep enabled'
    );

    my $menu = $win->menu;
    ok( $menu->checked('sweep_toggle'),
        'sweep_toggle menu checked by default' );
    ok( $menu->checked('speed_normal'),
        'speed_normal menu checked by default' );
    ok( !$menu->checked('speed_fast'), 'speed_fast menu not checked' );
    ok( !$menu->checked('speed_slow'), 'speed_slow menu not checked' );

    # Disable sweep via method
    $app->set_sweep_enabled(0);
    ok( !$app->{sweep_timer}->get_active, 'sweep_timer stopped when disabled' );
    ok( !$menu->checked('sweep_toggle'),  'sweep_toggle menu unchecked' );

    # Change speed to fast
    $app->set_sweep_speed('fast');
    ok( $menu->checked('speed_fast'),    'speed_fast menu checked' );
    ok( !$menu->checked('speed_normal'), 'speed_normal menu unchecked' );

    # Destroy window
    $win->destroy;
    ok( !$app->{sweep_timer}->get_active, 'timer inactive after destroy' );
};

subtest 'Phosphor decay calculation in Renderer' => sub {
    my $renderer = Games::GUI::Battleship::Renderer->new( cell_size => 32 );
    my $ship     = Games::GUI::Battleship::Ship->new(
        type => 'Destroyer',
        x    => 1,
        y    => 1,
        dir  => 'H',
    );

    # Ship center is at (1 - 1 + 2/2) * 32 = 32px
    # Board width is 320px
    # When progress = 32 / 320 = 0.10, the beam is directly at the ship center
    my $alpha_peak = $renderer->calc_ship_sweep_alpha( $ship, 32, 0.10 );
    ok( $alpha_peak >= 0.95 && $alpha_peak <= 1.0,
        "alpha is near maximum (~1.0) when beam is at ship (got $alpha_peak)" );

    # When beam is far away (e.g. progress = 0.95, distance ~ 0.85 board widths)
    # With decay constant k = 2.1, alpha at 0.85 distance is ~0.334
    my $alpha_decayed = $renderer->calc_ship_sweep_alpha( $ship, 32, 0.95 );
    ok( $alpha_decayed >= 0.20 && $alpha_decayed < 0.40,
        "alpha decays with balanced persistence (got $alpha_decayed)" );
    ok( $alpha_peak > $alpha_decayed,
        'peak alpha is strictly greater than decayed alpha' );
};

subtest 'Cairo rendering with radar sweep beam and fading' => sub {
    my $renderer = Games::GUI::Battleship::Renderer->new( cell_size => 32 );
    my $surf     = Cairo::ImageSurface->create( 'argb32', 940, 620 );
    my $cr       = Cairo::Context->create($surf);

    my $board = Games::GUI::Battleship::Board->new;
    $board->place_ship(
        Games::GUI::Battleship::Ship->new(
            type => 'Cruiser',
            x    => 2,
            y    => 2,
            dir  => 'H'
        )
    );

    # 1. Render with radar sweep enabled
    ok(
        lives {
            $renderer->render(
                $cr, 940, 620,
                phase               => 'battle',
                player_board        => $board,
                opponent_board      => $board,
                radar_sweep_enabled => 1,
                sweep_progress      => 0.45,
                status_msg          => 'Radar Sweep Active',
                ai_name             => 'ParityAI',
                ai_difficulty       => 'Normal',
            );
        },
        'renderer renders successfully with radar_sweep_enabled => 1'
    );

    # 2. Render with radar sweep disabled
    ok(
        lives {
            $renderer->render(
                $cr, 940, 620,
                phase               => 'battle',
                player_board        => $board,
                opponent_board      => $board,
                radar_sweep_enabled => 0,
                sweep_progress      => 0.0,
                status_msg          => 'Radar Sweep Disabled',
                ai_name             => 'ParityAI',
                ai_difficulty       => 'Normal',
            );
        },
        'renderer renders successfully with radar_sweep_enabled => 0'
    );

    # 3. Direct draw_radar_beam call at edge wrap-around
    ok(
        lives {
            my ( $pox, $poy ) = $renderer->player_origin;
            $renderer->draw_radar_beam( $cr, $pox, $poy, 0.02 );
            $renderer->draw_radar_beam( $cr, $pox, $poy, 0.98 );
        },
        'draw_radar_beam renders smoothly at edge boundaries'
    );

    # 4. Render with accuracy statistics from active combat shots
    $board->receive_shot( 2, 2 );    # hit Cruiser
    $board->receive_shot( 1, 1 );    # miss
    ok(
        lives {
            $renderer->render(
                $cr, 940, 620,
                phase          => 'battle',
                player_board   => $board,
                opponent_board => $board,
                status_msg     => 'Firing Phase',
                ai_name        => 'ParityAI',
                ai_difficulty  => 'Normal',
            );
        },
'renderer renders status bar with player and opponent accuracy statistics'
    );
};

done_testing;
1;


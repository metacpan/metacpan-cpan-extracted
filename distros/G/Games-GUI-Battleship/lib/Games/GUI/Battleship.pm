package Games::GUI::Battleship;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Carp qw(croak);

use Prima qw(Application MsgBox Cairo);
use Cairo;
use Time::HiRes qw(time);

use Games::GUI::Battleship::Ship;
use Games::GUI::Battleship::Board;
use Games::GUI::Battleship::Renderer;
use Games::GUI::Battleship::AI;

=pod

=head1 NAME

Games::GUI::Battleship - Play a game of Battleship through a GUI

=head1 VERSION

Version 1.0

=head1 SYNOPSIS

    battleship
    
=head1 DESCRIPTION

Play a game of Battleship against a computer opponent. It uses L<Prima> for the GUI and L<Cairo> for the graphics.

=for HTML <p>
<img src="https://github.com/mjohnson108/p5-Games-GUI-Battleship/blob/e80cfa124775dada0a0cefe168e3b980cfb3d7e4/examples/POD/battleship_screenshot.png?raw=true" alt="Screenshot of Battleship program" width="650">
</p>

=head2 Menus

=head3 Game

The I<New Game> option will start a new game at a given difficulty level.

I<Randomize Fleet> will reset any ongoing game and deploy your vessels in a random layout, bypassing the need for manually placing the vessels.

I<Reset Fleet> will reset the game.

I<Exit> exits the game.

=head3 Difficulty

Select the level of difficulty. There are three different settings, each backed by an "AI" with different play strategies.

=head3 Radar

Use I<Radar Sweep Effect> to toggle the scanning radar visual effect.

I<Speed> gives options on the speed of the radar sweep.

=head3 Help

I<How to Play> shows a short instructions dialog.

=head3 About 

shows a small about dialog.
    
=head2 How to play

Place vessels by clicking the mouse in the left grid. The game will highlight where the vessel will be placed. Use the space bar, "R" key, or right-click the mouse to rotate the vessel before placement.

Once all vessels are placed, click empty cells in the right grid to launch attacks on the opponent. The cell will record a hit or miss icon. Take turns trading attacks with the computer opponent until there is a winner.

=head1 SEE ALSO

L<Prima>

L<Logic::Relational>

=head1 AUTHOR

Matt Johnson, C<< <mjohnson at affectivesilicon.com> >>

=head1 AI

This game was developed with assistance from Gemini Flash 3.8.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Matt Johnson.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

    
=cut


our $VERSION = '1.0';

my %SWEEP_PERIODS = (
    slow   => 7.0,
    normal => 4.5,
    fast   => 2.5,
);

sub new ( $class, %args ) {
    my $difficulty = $args{difficulty} // 'normal';

    my $self = {
        difficulty     => $difficulty,
        ai             => Games::GUI::Battleship::AI->create($difficulty),
        player_board   => Games::GUI::Battleship::Board->new,
        opponent_board => Games::GUI::Battleship::Board->new,
        renderer       => Games::GUI::Battleship::Renderer->new,
        phase          => 'placement',    # placement, battle, game_over
        placement_idx  => 0,
        placement_dir  => 'H',
        ghost_ship     => undef,
        ghost_valid    => 0,
        hover_col      => undef,
        hover_row      => undef,
        hover_opp_col  => undef,
        hover_opp_row  => undef,
        status_msg     =>
'Deploy your Carrier (length 5). Left-click to place, Right-click or "R" to rotate.',
        msg_type            => 'info',
        window              => undef,
        ai_timer            => undef,
        radar_sweep_enabled => 1,
        radar_sweep_speed   => 'normal',
        sweep_progress      => 0.0,
        sweep_timer         => undef,
        last_sweep_time     => undef,
    };

    bless $self, $class;
    return $self;
}

sub run ($self) {
    $self->create_window;
    Prima->run;
    return;
}

sub create_window ($self) {
    my $initial_size = [ 940, 620 ];

    my $window = Prima::MainWindow->new(
        text => sprintf( 'Battleship [%s]',
            ucfirst( $self->{difficulty} ) ),
        size      => $initial_size,
        minSize   => [ 820, 560 ],
        layered   => 1,
        buffered  => 1,
        menuItems => $self->build_menu,
        onSize    => sub ( $w, @rest ) { $w->repaint },
        onPaint   => sub ( $w, $canvas, @rest ) {
            $self->handle_window_paint( $w, $canvas );
        },
        onMouseMove => sub ( $w, $mod, $x, $y, @rest ) {
            $self->handle_window_mouse_move( $w, $x, $y );
        },
        onMouseDown => sub ( $w, $btn, $mod, $x, $y, @rest ) {
            $self->handle_window_mouse_down( $w, $btn, $x, $y );
        },
        onDestroy => sub ( $w, @rest ) {
            $self->{ai_timer}->stop    if $self->{ai_timer};
            $self->{sweep_timer}->stop if $self->{sweep_timer};
        },
        onKeyDown => sub ( $w, $code, $key, $mod, @rest ) {
            $self->handle_window_key_down( $w, $code, $key );
        },
    );

# AI Turn Timer (allows player shot result to be perceived before AI retaliates)
    $self->{ai_timer} = Prima::Timer->new(
        timeout => 1800,
        onTick  => sub {
            $self->{ai_timer}->stop;
            $self->process_ai_turn;
        },
    );
    $self->{ai_timer}->stop;

    # Radar Sweep Animation Timer (~30 FPS, timeout 33ms)
    $self->{last_sweep_time} = Time::HiRes::time();
    $self->{sweep_timer}     = Prima::Timer->new(
        timeout => 33,
        onTick  => sub {
            $self->advance_sweep;
        },
    );
    if ( $self->{radar_sweep_enabled} ) {
        $self->{sweep_timer}->start;
    }
    else {
        $self->{sweep_timer}->stop;
    }

    $self->{window} = $window;
    $self->update_radar_menu;
    return $window;
}

sub handle_window_paint ( $self, $w, $canvas ) {
    $w->clear;
    my ( $vp_w, $vp_h ) = $w->size;
    my $cr = $canvas->cairo_context( transform => 0 );

    $self->{renderer}->render(
        $cr, $vp_w, $vp_h,
        phase               => $self->{phase},
        player_board        => $self->{player_board},
        opponent_board      => $self->{opponent_board},
        ghost_ship          => $self->{ghost_ship},
        ghost_valid         => $self->{ghost_valid},
        hover_opponent_col  => $self->{hover_opp_col},
        hover_opponent_row  => $self->{hover_opp_row},
        status_msg          => $self->{status_msg},
        msg_type            => $self->{msg_type},
        ai_name             => $self->{ai}->name,
        ai_difficulty       => ucfirst( $self->{ai}->difficulty ),
        radar_sweep_enabled => $self->{radar_sweep_enabled},
        sweep_progress      => $self->{sweep_progress},
    );
    return;
}

sub handle_window_mouse_move ( $self, $w, $x, $y ) {
    my ( $vp_w, $vp_h ) = $w->size;
    my $cx = $x;
    my $cy = $vp_h - $y;

    if ( $self->{phase} eq 'placement' ) {
        my ( $col, $row ) =
          $self->{renderer}->point_to_cell( $cx, $cy, 'player' );
        $self->{hover_col} = $col;
        $self->{hover_row} = $row;
        $self->update_placement_ghost( $col, $row );
        $w->repaint;
    }
    elsif ( $self->{phase} eq 'battle' ) {
        my ( $col, $row ) =
          $self->{renderer}->point_to_cell( $cx, $cy, 'opponent' );
        if (   ( $self->{hover_opp_col} // 0 ) != ( $col // 0 )
            || ( $self->{hover_opp_row} // 0 ) != ( $row // 0 ) )
        {
            $self->{hover_opp_col} = $col;
            $self->{hover_opp_row} = $row;
            $w->repaint;
        }
    }
    return;
}

sub handle_window_mouse_down ( $self, $w, $btn, $x, $y ) {
    my ( $vp_w, $vp_h ) = $w->size;
    my $cx = $x;
    my $cy = $vp_h - $y;

    # Right-click rotates current placement ship
    if ( $btn == mb::Right ) {
        if ( $self->{phase} eq 'placement' ) {
            $self->rotate_placement_ship;
            my ( $col, $row ) =
              $self->{renderer}->point_to_cell( $cx, $cy, 'player' );
            $self->{hover_col} = $col;
            $self->{hover_row} = $row;
            $self->update_placement_ghost( $col, $row );
            $w->repaint;
        }
        return;
    }

    return unless $btn == mb::Left;

    if ( $self->{phase} eq 'placement' ) {
        my ( $col, $row ) =
          $self->{renderer}->point_to_cell( $cx, $cy, 'player' );
        $self->handle_placement_click( $col, $row );
    }
    elsif ( $self->{phase} eq 'battle' ) {
        my ( $col, $row ) =
          $self->{renderer}->point_to_cell( $cx, $cy, 'opponent' );
        $self->handle_battle_click( $col, $row );
    }
    return;
}

sub handle_window_key_down ( $self, $w, $code, $key ) {
    if ( $key == kb::Space || chr($code) eq 'r' || chr($code) eq 'R' ) {
        if ( $self->{phase} eq 'placement' ) {
            $self->rotate_placement_ship;
            if (   defined $self->{hover_col}
                && defined $self->{hover_row} )
            {
                $self->update_placement_ghost( $self->{hover_col},
                    $self->{hover_row} );
            }
            $w->repaint;
        }
    }
    if ( ( $key == kb::Space || $key == kb::Enter )
        && $self->{phase} eq 'battle' )
    {
        if (   defined $self->{hover_opp_col}
            && defined $self->{hover_opp_row} )
        {
            $self->handle_battle_click( $self->{hover_opp_col},
                $self->{hover_opp_row} );
        }
    }
    return;
}

sub build_menu ($self) {
    return [
        [
            '~Game' => [
                [
                    '~New Game' => [
                        [
                            '~Easy (Naive AI)' => sub {
                                $self->start_new_game('easy');
                            }
                        ],
                        [
                            '~Normal (Parity AI)' => sub {
                                $self->start_new_game('normal');
                            }
                        ],
                        [
                            '~Hard (Probability AI)' => sub {
                                $self->start_new_game('hard');
                            }
                        ],
                    ]
                ],
                [
                    '~Randomize Fleet' => sub {
                        $self->randomize_player_fleet;
                    }
                ],
                [
                    'R~eset Fleet' => sub {
                        $self->reset_placement;
                    }
                ],
                [],
                [
                    'E~xit' => sub {
                        $self->{window}->close if $self->{window};
                    }
                ],
            ]
        ],
        [
            '~Difficulty' => [
                [
                    '~Easy (Naive AI)' => sub {
                        $self->start_new_game('easy');
                    }
                ],
                [
                    '~Normal (Parity AI)' => sub {
                        $self->start_new_game('normal');
                    }
                ],
                [
                    '~Hard (Probability AI)' => sub {
                        $self->start_new_game('hard');
                    }
                ],
            ]
        ],
        [
            '~Radar' => [
                [
                    '*sweep_toggle' => '~Radar Sweep Effect' => sub {
                        $self->set_sweep_enabled(
                            !$self->{radar_sweep_enabled} );
                    }
                ],
                [
                    '~Speed' => [
                        [
                            'speed_slow' => '~Slow (7.0s)' => sub {
                                $self->set_sweep_speed('slow');
                            }
                        ],
                        [
                            '*speed_normal' => '~Normal (4.5s)' => sub {
                                $self->set_sweep_speed('normal');
                            }
                        ],
                        [
                            'speed_fast' => '~Fast (2.5s)' => sub {
                                $self->set_sweep_speed('fast');
                            }
                        ],
                    ]
                ],
            ]
        ],
        [
            '~Help' => [
                [
                    '~How to Play' => sub {
                        $self->show_rules_dialog;
                    }
                ],

            ]
        ],
        [],
        [
            'About' => sub {
                $self->show_about_dialog;
            }
        ],
    ];
}

# ==============================================================================
# RADAR SWEEP ANIMATION & CONTROLS
# ==============================================================================

sub advance_sweep ( $self, $elapsed_sec = undef ) {
    return unless $self->{radar_sweep_enabled};

    my $now = Time::HiRes::time();
    my $dt;
    if ( defined $elapsed_sec ) {
        $dt = $elapsed_sec;
    }
    else {
        $dt =
          defined $self->{last_sweep_time}
          ? ( $now - $self->{last_sweep_time} )
          : 0.033;

        # Prevent large jumps if window was backgrounded or system paused
        $dt = 0.1 if $dt > 0.1;
    }
    $self->{last_sweep_time} = $now;

    my $period = $SWEEP_PERIODS{ $self->{radar_sweep_speed} } // 4.5;
    $self->{sweep_progress} = ( $self->{sweep_progress} + ( $dt / $period ) );
    if ( $self->{sweep_progress} >= 1.0 ) {
        $self->{sweep_progress} -= int( $self->{sweep_progress} );
    }

    $self->{window}->repaint if $self->{window};
    return;
}

sub set_sweep_enabled ( $self, $enabled ) {
    $self->{radar_sweep_enabled} = $enabled ? 1 : 0;
    if ( $self->{radar_sweep_enabled} ) {
        $self->{last_sweep_time} = Time::HiRes::time();
        $self->{sweep_timer}->start if $self->{sweep_timer};
    }
    else {
        $self->{sweep_timer}->stop if $self->{sweep_timer};
    }
    $self->update_radar_menu;
    $self->{window}->repaint if $self->{window};
    return;
}

sub set_sweep_speed ( $self, $speed ) {
    return unless exists $SWEEP_PERIODS{$speed};
    $self->{radar_sweep_speed} = $speed;
    $self->update_radar_menu;
    return;
}

sub update_radar_menu ($self) {
    return unless $self->{window} && $self->{window}->menu;
    my $menu = $self->{window}->menu;

    if ( $self->{radar_sweep_enabled} ) {
        $menu->check('sweep_toggle');
    }
    else {
        $menu->uncheck('sweep_toggle');
    }

    for my $spd (qw(slow normal fast)) {
        my $tag = 'speed_' . $spd;
        if ( $self->{radar_sweep_speed} eq $spd ) {
            $menu->check($tag);
        }
        else {
            $menu->uncheck($tag);
        }
    }
    return;
}

# ==============================================================================
# GAME STATE ACTIONS
# ==============================================================================

sub start_new_game ( $self, $difficulty = undef ) {
    $self->{ai_timer}->stop if $self->{ai_timer};
    $self->{difficulty} = $difficulty if defined $difficulty;
    $self->{ai} = Games::GUI::Battleship::AI->create( $self->{difficulty} );
    $self->{player_board}->clear_ships->reset_shots;
    $self->{opponent_board}->clear_ships->reset_shots;

    $self->{phase}         = 'placement';
    $self->{placement_idx} = 0;
    $self->{placement_dir} = 'H';
    $self->{ghost_ship}    = undef;
    $self->{ghost_valid}   = 0;
    $self->{hover_opp_col} = undef;
    $self->{hover_opp_row} = undef;

    my $first_ship = $Games::GUI::Battleship::Ship::FLEET_ORDER[0];
    my $len        = $Games::GUI::Battleship::Ship::SHIP_SIZES{$first_ship};
    $self->{status_msg} =
"Deploy your $first_ship (length $len). Left-click to place, Right-click or 'R' to rotate.";
    $self->{msg_type} = 'info';

    if ( $self->{window} ) {
        $self->{window}->text(
            sprintf( 'Battleship [%s]',
                ucfirst( $self->{difficulty} ) )
        );
        $self->{window}->repaint;
    }
    return;
}

sub rotate_placement_ship ($self) {
    $self->{placement_dir} = ( $self->{placement_dir} eq 'H' ) ? 'V' : 'H';
    if ( $self->{ghost_ship} ) {
        $self->{ghost_ship}->set_dir( $self->{placement_dir} );
        $self->{ghost_valid} =
          $self->{player_board}->can_place_ship( $self->{ghost_ship} );
    }
    return;
}

sub update_placement_ghost ( $self, $col, $row ) {
    if ( !defined $col || !defined $row ) {
        $self->{ghost_ship}  = undef;
        $self->{ghost_valid} = 0;
        return;
    }

    my $type =
      $Games::GUI::Battleship::Ship::FLEET_ORDER[ $self->{placement_idx} ];
    return unless $type;

    my $ship = Games::GUI::Battleship::Ship->new(
        type => $type,
        x    => $col,
        y    => $row,
        dir  => $self->{placement_dir},
    );

    $self->{ghost_ship}  = $ship;
    $self->{ghost_valid} = $self->{player_board}->can_place_ship($ship);
    return;
}

sub handle_placement_click ( $self, $col, $row ) {
    return unless defined $col        && defined $row;
    return unless $self->{ghost_ship} && $self->{ghost_valid};

    # Place the ship
    $self->{player_board}->place_ship( $self->{ghost_ship} );
    $self->{placement_idx}++;

    if ( $self->{placement_idx} <
        scalar @Games::GUI::Battleship::Ship::FLEET_ORDER )
    {
        my $next_ship =
          $Games::GUI::Battleship::Ship::FLEET_ORDER[ $self->{placement_idx} ];
        my $len = $Games::GUI::Battleship::Ship::SHIP_SIZES{$next_ship};
        $self->{status_msg} =
"Deploy your $next_ship (length $len). Left-click to place, Right-click or 'R' to rotate.";
        $self->{msg_type}   = 'info';
        $self->{ghost_ship} = undef;
    }
    else {
        # Fleet complete! Initialize AI fleet and begin battle
        $self->begin_battle;
    }

    $self->{window}->repaint if $self->{window};
    return;
}

sub randomize_player_fleet ( $self, $force = 0 ) {
    if ( !$force && $self->{phase} ne 'placement' ) {
        my $res = Prima::MsgBox::message_box(
            'Restart Game?',
            'Are you sure? This will restart the game.',
            mb::YesNo | mb::Warning
        );
        return unless $res == mb::Yes;
    }

    $self->{ai_timer}->stop if $self->{ai_timer};
    $self->{player_board}->clear_ships->reset_shots;
    $self->{opponent_board}->clear_ships->reset_shots;
    $self->{ai} = Games::GUI::Battleship::AI->create( $self->{difficulty} );
    $self->{ghost_ship}    = undef;
    $self->{ghost_valid}   = 0;
    $self->{hover_opp_col} = undef;
    $self->{hover_opp_row} = undef;

    $self->{player_board}->place_random_fleet;
    $self->{placement_idx} = scalar @Games::GUI::Battleship::Ship::FLEET_ORDER;
    $self->begin_battle;
    $self->{window}->repaint if $self->{window};
    return;
}

sub reset_placement ($self) {
    $self->{ai_timer}->stop if $self->{ai_timer};
    $self->{player_board}->clear_ships->reset_shots;
    $self->{opponent_board}->clear_ships->reset_shots;
    $self->{phase}         = 'placement';
    $self->{placement_idx} = 0;
    $self->{placement_dir} = 'H';
    $self->{ghost_ship}    = undef;
    $self->{ghost_valid}   = 0;
    $self->{hover_opp_col} = undef;
    $self->{hover_opp_row} = undef;

    my $first_ship = $Games::GUI::Battleship::Ship::FLEET_ORDER[0];
    my $len        = $Games::GUI::Battleship::Ship::SHIP_SIZES{$first_ship};
    $self->{status_msg} =
"Fleet reset. Deploy your $first_ship (length $len). Left-click to place.";
    $self->{msg_type} = 'info';
    $self->{window}->repaint if $self->{window};
    return;
}

sub begin_battle ($self) {
    $self->{ai_timer}->stop if $self->{ai_timer};
    $self->{opponent_board}->place_random_fleet;
    $self->{phase}      = 'battle';
    $self->{ghost_ship} = undef;
    $self->{status_msg} =
"Fleet deployed. Click a coordinate on the Enemy Radar to fire.";
    $self->{msg_type} = 'info';
    return;
}

sub handle_battle_click ( $self, $col, $row ) {
    return unless defined $col && defined $row;
    return unless $self->{phase} eq 'battle';
    return
      if $self->{ai_timer}
      && $self->{ai_timer}->get_active;    # Wait while AI turn is pending
    return if $self->{opponent_board}->has_shot( $col, $row );

    # Process Player Shot
    my $res = $self->{opponent_board}->receive_shot( $col, $row );
    return unless $res;

    my $coord_str = sprintf( "%s%d", ( 'A' .. 'J' )[ $col - 1 ], $row );
    my $ship_name = $res->{ship} ? $res->{ship}->type : 'Ship';

    if ( $res->{result} eq 'hit' ) {
        $self->{status_msg} =
          "DIRECT HIT! You struck the Enemy $ship_name at $coord_str!";
        $self->{msg_type} = 'hit';
    }
    elsif ( $res->{result} eq 'sunk' ) {
        $self->{status_msg} =
          "You SUNK the Enemy $ship_name at $coord_str!";
        $self->{msg_type} = 'sunk';
    }
    else {
        $self->{status_msg} = "Shot at $coord_str missed.";
        $self->{msg_type}   = 'miss';
    }

    $self->{window}->repaint if $self->{window};

    # Check Victory
    if ( $self->{opponent_board}->all_sunk ) {
        $self->{phase} = 'game_over';
        $self->{status_msg} =
          'VICTORY! You have completely wiped out the enemy fleet!';
        $self->{msg_type} = 'victory';
        $self->{window}->repaint if $self->{window};
        $self->show_game_over_dialog(1);
        return;
    }

# Queue AI retaliation with a pause so player can comfortably read shot feedback.
    my $delay =
      ( $res->{result} eq 'hit' || $res->{result} eq 'sunk' ) ? 1800 : 1400;
    $self->{ai_timer}->timeout($delay);
    $self->{ai_timer}->start;
    return;
}

sub process_ai_turn ($self) {
    return if $self->{phase} ne 'battle';

    my ( $ai_x, $ai_y, $ai_mode ) = $self->{ai}->select_target;
    return unless defined $ai_x && defined $ai_y;

    my $res = $self->{player_board}->receive_shot( $ai_x, $ai_y );
    return unless $res;

    $self->{ai}->record_result(
        x      => $ai_x,
        y      => $ai_y,
        result => $res->{result},
        ship   => $res->{ship},
    );

    my $coord_str = sprintf( "%s%d", ( 'A' .. 'J' )[ $ai_x - 1 ], $ai_y );
    my $ship_name = $res->{ship} ? $res->{ship}->type : 'Ship';

    if ( $res->{result} eq 'hit' ) {
        $self->{status_msg} =
          "WARNING! Enemy hit your $ship_name at $coord_str! ($ai_mode)";
        $self->{msg_type} = 'hit';
    }
    elsif ( $res->{result} eq 'sunk' ) {
        $self->{status_msg} =
          "CRITICAL HIT! Enemy SUNK your $ship_name at $coord_str! ($ai_mode)";
        $self->{msg_type} = 'sunk';
    }
    else {
        $self->{status_msg} =
          "Enemy fired at $coord_str: MISS! ($ai_mode). Your turn to attack.";
        $self->{msg_type} = 'info';
    }

    $self->{window}->repaint if $self->{window};

    # Check Defeat
    if ( $self->{player_board}->all_sunk ) {
        $self->{phase} = 'game_over';
        $self->{status_msg} =
          'DEFEAT! The enemy has sunk your entire fleet.';
        $self->{msg_type} = 'defeat';
        $self->{window}->repaint if $self->{window};
        $self->show_game_over_dialog(0);
    }
    return;
}

# ==============================================================================
# DIALOGS
# ==============================================================================

sub show_game_over_dialog ( $self, $player_won ) {
    my $title = $player_won ? 'VICTORY!' : 'DEFEAT!';
    my $text =
      $player_won
      ? "Congratulations! You destroyed the enemy fleet.\n\nPlay again?"
      : "Your fleet was lost.\nThe enemy prevailed.\n\nPlay again?";

    my $res =
      Prima::MsgBox::message_box( $title, $text, mb::YesNo );

    if ( $res == mb::Yes ) {
        $self->start_new_game;
    }
    
    return;
}

sub show_rules_dialog ($self) {
    my $rules = <<~'RULES';
    BATTLESHIP RULES:
    1. Deployment Phase:
       - Place each of your 5 vessels on your fleet grid.
       - Left-Click to place at the highlighted coordinate.
       - Right-Click, press Space, or "R" key to rotate/switch between horizontal and vertical.
       - Or choose "Game -> Randomize Fleet" to auto-deploy.
    
    2. Combat Phase:
       - Take turns with the AI firing at enemy coordinates.
       - Left-Click or press Space/Enter on any unexplored cell of the Tactical Radar.
       - Hits and misses are marked on the grid.
       - Sinking all 5 enemy ships wins the battle.
    
    3. AI Opponents:
       - Easy: Naive AI (Linear scanning + adjacent probing)
       - Normal: Parity AI (Checkerboard parity hunt + line extension)
       - Hard: Probability AI (Probability density heatmap + dynamic parity)
    RULES

    Prima::MsgBox::message_box( 'Rules and Instructions',
        $rules, mb::Ok );
        
    return;
}

sub show_about_dialog ($self) {
    my $about = <<~'ABOUT';
    Games::GUI::Battleship v1
    by Matt Johnson (MJOHNSON)
    ABOUT

    Prima::MsgBox::message_box( 'About Battleship',
        $about, mb::Ok | mb::Information );
        
    return;
}


1;


package Games::GUI::Battleship::Renderer;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Cairo;
use List::Util qw(min max);

# Math constant
my $PI = 3.14159265358979323846;

sub new ( $class, %args ) {
    my $self = {
        cell_size       => 32,
        player_origin   => [ 50,  80 ],
        opponent_origin => [ 460, 80 ],
        header_height   => 60,
        label_margin    => 26,
    };
    return bless $self, $class;
}

sub cell_size ($self) {
    return $self->{cell_size};
}

sub player_origin ($self) {
    return @{ $self->{player_origin} };
}

sub opponent_origin ($self) {
    return @{ $self->{opponent_origin} };
}

sub update_layout ( $self, $vp_w, $vp_h ) {
    $self->{vp_w} = $vp_w;
    $self->{vp_h} = $vp_h;

    my $w_factor = $vp_w / 940;

    # Header height scales smoothly with window height and width
    my $header_h = int( 72 + ( $vp_h - 600 ) * 0.05 + ( $vp_w - 900 ) * 0.035 );
    $header_h = max( 74, min( 170, $header_h ) );

    # Footer height scales with height and width
    my $footer_h = int( 40 + ( $vp_h - 600 ) * 0.03 + ( $vp_w - 900 ) * 0.015 );
    $footer_h = max( 42, min( 75, $footer_h ) );

    # Dynamic label margin around each board for larger titles and labels
    my $avail_h_est = $vp_h - $header_h - $footer_h - 40;
    my $avail_w_est = ( $vp_w - 60 - 80 ) / 2;
    my $cs_est      = min( int( $avail_h_est / 10 ), int( $avail_w_est / 10 ) );
    $cs_est = max( 24, min( 140, $cs_est ) );

    my $label_m = int( 28 + ( $cs_est * 0.28 ) + ( $vp_w * 0.012 ) );
    $label_m = max( 32, min( 80, $label_m ) );
    $self->{label_margin} = $label_m;

    my $avail_h = $vp_h - $header_h - $footer_h - $label_m;
    my $avail_w = ( $vp_w - 60 - ( 2 * $label_m ) ) / 2;

    my $cs_h = int( $avail_h / 10 );
    my $cs_w = int( $avail_w / 10 );

    my $cs = min( $cs_h, $cs_w );
    $cs = max( 24, min( 140, $cs ) );
    $self->{cell_size} = $cs;

    my $board_px = 10 * $cs;
    my $gap =
      max( 24, int( ( $vp_w - ( 2 * $board_px ) - ( 2 * $label_m ) ) / 3 ) );
    $gap = min( 120, $gap );

    my $total_w = ( 2 * $board_px ) + ( 2 * $label_m ) + $gap;
    my $start_x = max( 15, int( ( $vp_w - $total_w ) / 2 ) );
    my $start_y = $header_h + $label_m;

    $self->{player_origin} = [ $start_x + $label_m, $start_y ];
    $self->{opponent_origin} =
      [ $start_x + $board_px + $label_m + $gap + $label_m, $start_y ];

    return $cs;
}

sub point_to_cell ( $self, $px, $py, $board_type ) {
    my ( $ox, $oy ) =
      ( $board_type eq 'player' )
      ? $self->player_origin
      : $self->opponent_origin;

    my $cs = $self->{cell_size};
    if (   $px >= $ox
        && $px < $ox + ( 10 * $cs )
        && $py >= $oy
        && $py < $oy + ( 10 * $cs ) )
    {
        my $col = 1 + int( ( $px - $ox ) / $cs );
        my $row = 1 + int( ( $py - $oy ) / $cs );
        return ( $col, $row );
    }
    return;
}

sub cell_to_rect ( $self, $col, $row, $board_type ) {
    my ( $ox, $oy ) =
      ( $board_type eq 'player' )
      ? $self->player_origin
      : $self->opponent_origin;
    my $cs = $self->{cell_size};
    my $x  = $ox + ( ( $col - 1 ) * $cs );
    my $y  = $oy + ( ( $row - 1 ) * $cs );
    return ( $x, $y, $cs, $cs );
}

# ==============================================================================
# MAIN RENDER ENTRY POINT
# ==============================================================================

sub render ( $self, $cr, $vp_w, $vp_h, %state ) {
    $self->update_layout( $vp_w, $vp_h );

    # 1. Background
    $self->draw_background( $cr, $vp_w, $vp_h );

    # 2. Header & Status
    $self->draw_status_bar( $cr, $vp_w, $vp_h, %state );

    # 3. Player Fleet Board
    $self->draw_board_grid(
        $cr, 'player',
        'YOUR FLEET (DEFENSE)',
        $state{phase} eq 'placement' ? 1 : 0
    );

    # 4. Opponent Radar Board
    $self->draw_board_grid(
        $cr, 'opponent',
        'TACTICAL RADAR (ATTACK)',
        $state{phase} eq 'battle' ? 1 : 0
    );

    # 5. Draw Player's Placed Ships
    if ( $state{player_board} ) {
        my ( $pox, $poy ) = $self->player_origin;
        for my $ship ( $state{player_board}->ships ) {
            $self->draw_ship(
                $cr, $ship, $pox, $poy, $self->{cell_size},
                sunk           => $ship->is_sunk,
                radar_sweep    => $state{radar_sweep_enabled},
                sweep_progress => $state{sweep_progress},
            );
        }
    }

    # 6. Draw Placement Ghost Silhouette (if placing ships)
    if (   $state{phase} eq 'placement'
        && $state{ghost_ship}
        && $state{ghost_valid} ne '' )
    {
        my ( $pox, $poy ) = $self->player_origin;
        $self->draw_ship(
            $cr,
            $state{ghost_ship},
            $pox,
            $poy,
            $self->{cell_size},
            ghost => 1,
            valid => $state{ghost_valid}
        );
    }

    # 7. Draw Opponent's Sunk Ships (revealed on radar)
    if ( $state{opponent_board} ) {
        my ( $oox, $ooy ) = $self->opponent_origin;
        for my $ship ( $state{opponent_board}->ships ) {
            if ( $ship->is_sunk || $state{phase} eq 'game_over' ) {
                $self->draw_ship(
                    $cr, $ship, $oox, $ooy, $self->{cell_size},
                    sunk           => 1,
                    radar_sweep    => $state{radar_sweep_enabled},
                    sweep_progress => $state{sweep_progress},
                );
            }
        }
    }

    # 7.5 Draw Radar Sweep Beams on both boards (if enabled)
    if ( $state{radar_sweep_enabled} ) {
        my $progress = $state{sweep_progress} // 0.0;
        my ( $pox, $poy ) = $self->player_origin;
        my ( $oox, $ooy ) = $self->opponent_origin;
        $self->draw_radar_beam( $cr, $pox, $poy, $progress );
        $self->draw_radar_beam( $cr, $oox, $ooy, $progress );
    }

    # 8. Draw Shots on Player Board (AI attacks)
    if ( $state{player_board} ) {
        my ( $pox, $poy ) = $self->player_origin;
        $self->draw_shots( $cr, $state{player_board}, $pox, $poy );
    }

    # 9. Draw Shots on Opponent Board (Player attacks)
    if ( $state{opponent_board} ) {
        my ( $oox, $ooy ) = $self->opponent_origin;
        $self->draw_shots( $cr, $state{opponent_board}, $oox, $ooy );
    }

    # 10. Draw Hover Reticle (Opponent board during battle)
    if (   $state{phase} eq 'battle'
        && $state{hover_opponent_col}
        && $state{hover_opponent_row} )
    {
        my ( $hx, $hy, $hw, $hh ) =
          $self->cell_to_rect( $state{hover_opponent_col},
            $state{hover_opponent_row}, 'opponent' );
        $self->draw_reticle( $cr, $hx, $hy, $hw, $hh );
    }

    return;
}

# ==============================================================================
# DRAWING PRIMITIVES
# ==============================================================================

sub draw_background ( $self, $cr, $w, $h ) {
    my $pat = Cairo::LinearGradient->create( 0, 0, 0, $h );
    $pat->add_color_stop_rgb( 0, 0.05, 0.08, 0.14 );
    $pat->add_color_stop_rgb( 1, 0.02, 0.04, 0.08 );
    $cr->set_source($pat);
    $cr->rectangle( 0, 0, $w, $h );
    $cr->fill;
    return;
}

sub draw_status_bar ( $self, $cr, $w, $h, %state ) {
    my $cs       = $self->{cell_size};
    my $w_factor = $w / 940;

    # Sub-headline status banner: scales smoothly with width
    my $status_msg  = $state{status_msg} // 'Ready.';
    my $status_font = max( 14, int( 15 * $w_factor ) );

    # Header title badge: at least as big as the status banner text beneath it
    my $title_font = max( 20, int( $cs * 0.45 ), int( $status_font * 1.15 ) );
    $cr->select_font_face( "sans-serif", 'normal', 'bold' );
    $cr->set_font_size($title_font);
    $cr->set_source_rgb( 0.85, 0.92, 1.0 );
    my $title_y = max( 28, int( $title_font * 1.18 ) );
    $cr->move_to( 30, $title_y );
    $cr->show_text("BATTLESHIP");
    my $t_ext = $cr->text_extents("BATTLESHIP");

    # Difficulty & Mode indicator: scales with width, subordinate to title
    my $info_font =
      max( 12, min( int( $title_font * 0.65 ), int( 13 * $w_factor ) ) );
    $cr->select_font_face( "sans-serif", 'normal', 'normal' );
    $cr->set_font_size($info_font);
    $cr->set_source_rgb( 0.45, 0.65, 0.85 );
    my $diff_offset =
      30 + $t_ext->{x_advance} + max( 20, int( $info_font * 1.2 ) );
    $cr->move_to( $diff_offset, $title_y );
    my $diff_text = sprintf(
        "Opponent: %s (%s AI)",
        ( $state{ai_name}       // 'ParityAI' ),
        ( $state{ai_difficulty} // 'Normal' )
    );
    $cr->show_text($diff_text);

    # Sub-headline status banner drawing
    $cr->select_font_face( "sans-serif", 'normal', 'normal' );
    $cr->set_font_size($status_font);

    my %type_colors = (
        hit     => [ 1.0,  0.35, 0.25 ],
        sunk    => [ 1.0,  0.80, 0.20 ],
        victory => [ 0.30, 0.90, 0.40 ],
        defeat  => [ 0.90, 0.20, 0.20 ],
    );
    my $color = $type_colors{ $state{msg_type} // '' } // [ 0.75, 0.85, 0.95 ];
    $cr->set_source_rgb(@$color);

    my $status_y = $title_y + max( 22, int( $status_font * 1.35 ) );
    $cr->move_to( 30, $status_y );
    $cr->show_text($status_msg);

# Footer fleet status counts and accuracy statistics: scales smoothly with width
    if ( $state{player_board} && $state{opponent_board} ) {
        my $p_rem = $state{player_board}->ships_remaining;
        my $o_rem = $state{opponent_board}->ships_remaining;
        my $p_acc = $state{player_accuracy}
          // $state{opponent_board}->shot_accuracy;
        my $o_acc = $state{opponent_accuracy}
          // $state{player_board}->shot_accuracy;

        my $foot_font = max( 12, int( 12 * $w_factor ) );
        $cr->select_font_face( "sans-serif", 'normal', 'normal' );
        $cr->set_font_size($foot_font);
        $cr->set_source_rgb( 0.55, 0.68, 0.82 );
        my $stat_str =
          sprintf(
"Fleet Status:  Friendly Ships: %d/5   |   Enemy Ships: %d/5   |   Accuracy:  Player: %.1f%%   |   Enemy: %.1f%%",
            $p_rem, $o_rem, $p_acc, $o_acc );
        $cr->move_to( 30, $h - max( 8, int( $foot_font * 1 ) ) );
        $cr->show_text($stat_str);
    }
    return;
}

sub draw_board_grid ( $self, $cr, $board_type, $title, $active = 0 ) {
    my ( $ox, $oy ) =
      ( $board_type eq 'player' )
      ? $self->player_origin
      : $self->opponent_origin;
    my $cs       = $self->{cell_size};
    my $bw       = 10 * $cs;
    my $bh       = 10 * $cs;
    my $w_factor = $self->{vp_w} ? ( $self->{vp_w} / 940 ) : 1.0;

    # Board Title Badge: scales with both width and cell size
    my $title_font = max( 13, int( 13 * $w_factor ) );
    $title_font = int( $cs * 0.32 ) if int( $cs * 0.32 ) > $title_font;

    # Label font (A..J and 1..10): scales with cell size & width
    my $label_font = max( 11, int( $cs * 0.34 ) );
    my $w_lbl      = int( 11 * $w_factor );
    $label_font = $w_lbl if $w_lbl > $label_font;

    $cr->select_font_face( "sans-serif", 'normal', 'bold' );
    $cr->set_font_size($title_font);
    if ($active) {
        $cr->set_source_rgb( 0.3, 0.85, 1.0 );
    }
    else {
        $cr->set_source_rgb( 0.45, 0.55, 0.68 );
    }
    my $title_y = $oy - $label_font - max( 8, int( $title_font * 0.55 ) );
    $cr->move_to( $ox, $title_y );
    $cr->show_text($title);

    # Ocean surface
    $cr->rectangle( $ox, $oy, $bw, $bh );
    $cr->set_source_rgb( 0.08, 0.13, 0.21 );
    $cr->fill;

    # Grid Lines
    $cr->set_line_width( max( 1, $cs * 0.025 ) );
    $cr->set_source_rgba( 0.18, 0.30, 0.44, 0.65 );

    for my $i ( 0 .. 10 ) {

        # Vertical
        $cr->move_to( $ox + ( $i * $cs ), $oy );
        $cr->line_to( $ox + ( $i * $cs ), $oy + $bh );
        $cr->stroke;

        # Horizontal
        $cr->move_to( $ox, $oy + ( $i * $cs ) );
        $cr->line_to( $ox + $bw, $oy + ( $i * $cs ) );
        $cr->stroke;
    }

    # Outer border
    $cr->rectangle( $ox, $oy, $bw, $bh );
    if ($active) {
        $cr->set_line_width( max( 2, $cs * 0.045 ) );
        $cr->set_source_rgba( 0.2, 0.7, 0.95, 0.8 );
    }
    else {
        $cr->set_line_width( max( 1.5, $cs * 0.035 ) );
        $cr->set_source_rgba( 0.25, 0.38, 0.52, 0.8 );
    }
    $cr->stroke;

    # Row numbers (1..10) and Column letters (A..J)
    $cr->select_font_face( "sans-serif", 'normal', 'normal' );
    $cr->set_font_size($label_font);
    $cr->set_source_rgb( 0.45, 0.58, 0.72 );

    my @cols = ( 'A' .. 'J' );
    for my $c ( 0 .. 9 ) {
        my $tx =
          $ox + ( $c * $cs ) + int( $cs / 2 ) - int( $label_font * 0.32 );
        my $ty = $oy - max( 5, int( $label_font * 0.30 ) );
        $cr->move_to( $tx, $ty );
        $cr->show_text( $cols[$c] );
    }

    for my $r ( 1 .. 10 ) {
        my $tx = $ox - int( $label_font * 1.55 );
        $tx -= int( $label_font * 0.45 ) if $r == 10;
        my $ty =
          $oy +
          ( ( $r - 1 ) * $cs ) +
          int( $cs / 2 ) +
          int( $label_font * 0.35 );
        $cr->move_to( $tx, $ty );
        $cr->show_text("$r");
    }

    return;
}

sub draw_shots ( $self, $cr, $board, $ox, $oy ) {
    my $cs = $self->{cell_size};

    for my $y ( 1 .. 10 ) {
        for my $x ( 1 .. 10 ) {
            my $shot = $board->shot_at( $x, $y );
            next unless $shot;

            my $cx = $ox + ( ( $x - 1 ) * $cs ) + ( $cs / 2 );
            my $cy = $oy + ( ( $y - 1 ) * $cs ) + ( $cs / 2 );

            if ( $shot eq 'M' ) {
                $self->draw_miss_marker( $cr, $cx, $cy, $cs );
            }
            elsif ( $shot eq 'H' || $shot eq 'S' ) {
                $self->draw_hit_marker( $cr, $cx, $cy, $cs, $shot eq 'S' );
            }
        }
    }
    return;
}

sub draw_miss_marker ( $self, $cr, $cx, $cy, $cs ) {
    my $r = $cs * 0.22;

    # Ripple ring 1
    $cr->set_line_width(1.5);
    $cr->set_source_rgba( 0.85, 0.92, 1.0, 0.7 );
    $cr->arc( $cx, $cy, $r, 0, 2 * $PI );
    $cr->stroke;

    # Center white water bead
    $cr->set_source_rgba( 0.9, 0.95, 1.0, 0.9 );
    $cr->arc( $cx, $cy, 2.5, 0, 2 * $PI );
    $cr->fill;
    return;
}

sub draw_hit_marker ( $self, $cr, $cx, $cy, $cs, $is_sunk = 0 ) {
    my $r = $cs * 0.32;

    # Fire blast radial gradient
    my $pat = Cairo::RadialGradient->create( $cx, $cy, 2, $cx, $cy, $r );
    if ($is_sunk) {
        $pat->add_color_stop_rgba( 0,   1.0, 0.9,  0.3,  1.0 );
        $pat->add_color_stop_rgba( 0.5, 0.9, 0.2,  0.1,  0.9 );
        $pat->add_color_stop_rgba( 1,   0.4, 0.05, 0.05, 0.0 );
    }
    else {
        $pat->add_color_stop_rgba( 0,   1.0, 1.0,  0.6, 1.0 );
        $pat->add_color_stop_rgba( 0.4, 1.0, 0.4,  0.1, 0.9 );
        $pat->add_color_stop_rgba( 1,   0.8, 0.15, 0.1, 0.0 );
    }

    $cr->set_source($pat);
    $cr->arc( $cx, $cy, $r, 0, 2 * $PI );
    $cr->fill;

    # Sharp central explosion pin
    $cr->set_source_rgb( 1.0, 0.95, 0.8 );
    $cr->arc( $cx, $cy, 3, 0, 2 * $PI );
    $cr->fill;

    # Cross spikes
    $cr->set_line_width(1.5);
    $cr->set_source_rgba( 1.0, 0.3, 0.2, 0.8 );
    $cr->move_to( $cx - ( $r * 0.7 ), $cy );
    $cr->line_to( $cx + ( $r * 0.7 ), $cy );
    $cr->stroke;
    $cr->move_to( $cx, $cy - ( $r * 0.7 ) );
    $cr->line_to( $cx, $cy + ( $r * 0.7 ) );
    $cr->stroke;
    return;
}

sub draw_reticle ( $self, $cr, $x, $y, $w, $h ) {
    my $pad = 2;
    $cr->set_line_width(1.5);
    $cr->set_source_rgba( 0.2, 0.9, 1.0, 0.8 );
    $cr->rectangle( $x + $pad, $y + $pad, $w - ( 2 * $pad ),
        $h - ( 2 * $pad ) );
    $cr->stroke;

    # Crosshair ticks
    my $cx = $x + ( $w / 2 );
    my $cy = $y + ( $h / 2 );
    $cr->move_to( $cx - 4, $cy );
    $cr->line_to( $cx + 4, $cy );
    $cr->stroke;
    $cr->move_to( $cx, $cy - 4 );
    $cr->line_to( $cx, $cy + 4 );
    $cr->stroke;
    return;
}

# ==============================================================================
# VECTOR SHIP RENDERING
# ==============================================================================

sub draw_ship ( $self, $cr, $ship, $ox, $oy, $cs, %opts ) {
    my $sx  = $ox + ( ( $ship->x - 1 ) * $cs );
    my $sy  = $oy + ( ( $ship->y - 1 ) * $cs );
    my $len = $ship->length;
    my $dir = $ship->dir;

    $cr->save;

    # Position and orient to canonical horizontal drawing
    $cr->translate( $sx, $sy );
    if ( $dir eq 'V' ) {
        $cr->translate( $cs, 0 );
        $cr->rotate( $PI / 2 );
    }

    my $w = $len * $cs;
    my $h = $cs;

    if ( $opts{ghost} ) {
        my $valid = $opts{valid} // 1;
        $self->draw_ghost_hull( $cr, $ship->type, $w, $h, $valid );
    }
    else {
        my $method   = 'draw_' . lc( $ship->type );
        my $draw_sub = $self->can($method) ? $method : 'draw_generic_hull';

        if ( $opts{radar_sweep} ) {
            my $progress = $opts{sweep_progress} // 0.0;
            my $alpha = $self->calc_ship_sweep_alpha( $ship, $cs, $progress );
            $cr->push_group;
            $self->$draw_sub( $cr, $w, $h, %opts );
            $cr->pop_group_to_source;
            $cr->paint_with_alpha($alpha);
        }
        else {
            $self->$draw_sub( $cr, $w, $h, %opts );
        }
    }

    $cr->restore;
    return;
}

sub draw_ghost_hull ( $self, $cr, $type, $w, $h, $valid ) {
    my ( $pad_x, $pad_y ) = ( 3, 3 );
    my $rw = $w - ( 2 * $pad_x );
    my $rh = $h - ( 2 * $pad_y );

    $cr->rectangle( $pad_x, $pad_y, $rw, $rh );
    if ($valid) {
        $cr->set_source_rgba( 0.1, 0.7, 0.9, 0.35 );
        $cr->fill_preserve;
        $cr->set_line_width(2);
        $cr->set_source_rgba( 0.2, 0.9, 1.0, 0.9 );
        $cr->stroke;
    }
    else {
        $cr->set_source_rgba( 0.9, 0.1, 0.1, 0.35 );
        $cr->fill_preserve;
        $cr->set_line_width(2);
        $cr->set_source_rgba( 1.0, 0.2, 0.2, 0.9 );
        $cr->stroke;

        # Warning cross-line
        $cr->move_to( $pad_x, $pad_y );
        $cr->line_to( $pad_x + $rw, $pad_y + $rh );
        $cr->stroke;
    }
    return;
}

# --- 1. CARRIER (Size 5) ---
sub draw_carrier ( $self, $cr, $w, $h, %opts ) {
    my ( $x0, $y0 ) = ( 3, 3 );
    my $cw = $w - 6;
    my $ch = $h - 6;
    my $yc = $h / 2;

    # Flight deck polygonal hull
    $cr->move_to( $x0 + 8, $y0 );
    $cr->line_to( $x0 + $cw - 4, $y0 );
    $cr->line_to( $x0 + $cw,     $y0 + 5 );
    $cr->line_to( $x0 + $cw,     $y0 + $ch - 5 );
    $cr->line_to( $x0 + $cw - 4, $y0 + $ch );
    $cr->line_to( $x0 + 8,       $y0 + $ch );
    $cr->line_to( $x0,           $yc );
    $cr->close_path;

    if ( $opts{sunk} ) {
        $cr->set_source_rgb( 0.16, 0.18, 0.20 );
        $cr->fill_preserve;
        $cr->set_line_width(1.5);
        $cr->set_source_rgb( 0.7, 0.2, 0.2 );
        $cr->stroke;
        return;
    }

    $cr->set_source_rgb( 0.22, 0.25, 0.30 );
    $cr->fill_preserve;
    $cr->set_line_width(1.5);
    $cr->set_source_rgb( 0.45, 0.52, 0.62 );
    $cr->stroke;

    # Angled runway line
    $cr->set_line_width(1);
    $cr->set_source_rgba( 0.85, 0.90, 0.95, 0.6 );
    $cr->set_dash( 0, 4, 3 );
    $cr->move_to( $x0 + 12, $yc );
    $cr->line_to( $x0 + $cw - 8, $yc );
    $cr->stroke;
    $cr->set_dash(0);

    # Island superstructure (starboard tower)
    my $ix = $x0 + ( $cw * 0.48 );
    my $iy = $y0 + 2;
    $cr->rectangle( $ix, $iy, $cw * 0.14, $ch * 0.28 );
    $cr->set_source_rgb( 0.35, 0.40, 0.48 );
    $cr->fill_preserve;
    $cr->set_line_width(1);
    $cr->set_source_rgb( 0.6, 0.7, 0.8 );
    $cr->stroke;

    # Radar mast on island
    $cr->move_to( $ix + ( $cw * 0.07 ), $iy );
    $cr->line_to( $ix + ( $cw * 0.07 ), $iy - 2 );
    $cr->stroke;
    return;
}

# --- 2. BATTLESHIP (Size 4) ---
sub draw_battleship ( $self, $cr, $w, $h, %opts ) {
    my ( $x0, $y0 ) = ( 3, 3 );
    my $cw = $w - 6;
    my $ch = $h - 6;
    my $yc = $h / 2;

    # Armored warship clipper hull
    $cr->move_to( $x0, $yc );
    $cr->curve_to( $x0 + 18, $y0, $x0 + 30, $y0, $x0 + $cw - 8, $y0 );
    $cr->curve_to(
        $x0 + $cw, $y0 + 4, $x0 + $cw,
        $y0 + $ch - 4,
        $x0 + $cw - 8,
        $y0 + $ch
    );
    $cr->curve_to( $x0 + 30, $y0 + $ch, $x0 + 18, $y0 + $ch, $x0, $yc );
    $cr->close_path;

    if ( $opts{sunk} ) {
        $cr->set_source_rgb( 0.18, 0.20, 0.22 );
        $cr->fill_preserve;
        $cr->set_line_width(1.5);
        $cr->set_source_rgb( 0.7, 0.2, 0.2 );
        $cr->stroke;
        return;
    }

    $cr->set_source_rgb( 0.28, 0.33, 0.40 );
    $cr->fill_preserve;
    $cr->set_line_width(1.5);
    $cr->set_source_rgb( 0.50, 0.58, 0.68 );
    $cr->stroke;

    # Central Command Bridge Tower
    my $bx = $x0 + ( $cw * 0.38 );
    my $bw = $cw * 0.24;
    $cr->rectangle( $bx, $yc - ( $ch * 0.22 ), $bw, $ch * 0.44 );
    $cr->set_source_rgb( 0.38, 0.44, 0.52 );
    $cr->fill_preserve;
    $cr->set_line_width(1);
    $cr->set_source_rgb( 0.6, 0.7, 0.8 );
    $cr->stroke;

    # Forward Gun Turret (base + twin barrels)
    my $t1_x = $x0 + ( $cw * 0.20 );
    $cr->arc( $t1_x, $yc, $ch * 0.22, 0, 2 * $PI );
    $cr->set_source_rgb( 0.22, 0.26, 0.32 );
    $cr->fill;
    $cr->set_line_width(1.5);
    $cr->set_source_rgb( 0.6, 0.7, 0.8 );
    $cr->move_to( $t1_x, $yc - 2 );
    $cr->line_to( $t1_x - ( $cw * 0.10 ), $yc - 2 );
    $cr->stroke;
    $cr->move_to( $t1_x, $yc + 2 );
    $cr->line_to( $t1_x - ( $cw * 0.10 ), $yc + 2 );
    $cr->stroke;

    # Aft Gun Turret (base + twin barrels pointing aft)
    my $t2_x = $x0 + ( $cw * 0.78 );
    $cr->arc( $t2_x, $yc, $ch * 0.22, 0, 2 * $PI );
    $cr->set_source_rgb( 0.22, 0.26, 0.32 );
    $cr->fill;
    $cr->set_line_width(1.5);
    $cr->set_source_rgb( 0.6, 0.7, 0.8 );
    $cr->move_to( $t2_x, $yc - 2 );
    $cr->line_to( $t2_x + ( $cw * 0.10 ), $yc - 2 );
    $cr->stroke;
    $cr->move_to( $t2_x, $yc + 2 );
    $cr->line_to( $t2_x + ( $cw * 0.10 ), $yc + 2 );
    $cr->stroke;
    return;
}

# --- 3. CRUISER (Size 3) ---
sub draw_cruiser ( $self, $cr, $w, $h, %opts ) {
    my ( $x0, $y0 ) = ( 3, 3 );
    my $cw = $w - 6;
    my $ch = $h - 6;
    my $yc = $h / 2;

    # Streamlined hull
    $cr->move_to( $x0, $yc );
    $cr->line_to( $x0 + 16,      $y0 + 1 );
    $cr->line_to( $x0 + $cw - 4, $y0 + 2 );
    $cr->line_to( $x0 + $cw,     $yc );
    $cr->line_to( $x0 + $cw - 4, $y0 + $ch - 2 );
    $cr->line_to( $x0 + 16,      $y0 + $ch - 1 );
    $cr->close_path;

    if ( $opts{sunk} ) {
        $cr->set_source_rgb( 0.18, 0.20, 0.22 );
        $cr->fill_preserve;
        $cr->set_line_width(1.5);
        $cr->set_source_rgb( 0.7, 0.2, 0.2 );
        $cr->stroke;
        return;
    }

    $cr->set_source_rgb( 0.32, 0.37, 0.44 );
    $cr->fill_preserve;
    $cr->set_line_width(1.5);
    $cr->set_source_rgb( 0.52, 0.60, 0.70 );
    $cr->stroke;

    # Twin smokestacks
    my $f1_x = $x0 + ( $cw * 0.45 );
    my $f2_x = $x0 + ( $cw * 0.62 );
    for my $fx ( $f1_x, $f2_x ) {
        $cr->rectangle( $fx, $yc - ( $ch * 0.22 ), $cw * 0.08, $ch * 0.44 );
        $cr->set_source_rgb( 0.24, 0.28, 0.34 );
        $cr->fill_preserve;
        $cr->set_line_width(1);
        $cr->set_source_rgb( 0.6, 0.7, 0.8 );
        $cr->stroke;
    }

    # Forward deck gun
    my $tx = $x0 + ( $cw * 0.22 );
    $cr->arc( $tx, $yc, $ch * 0.20, 0, 2 * $PI );
    $cr->set_source_rgb( 0.22, 0.26, 0.32 );
    $cr->fill;
    $cr->set_line_width(1.5);
    $cr->set_source_rgb( 0.6, 0.7, 0.8 );
    $cr->move_to( $tx, $yc );
    $cr->line_to( $tx - ( $cw * 0.10 ), $yc );
    $cr->stroke;
    return;
}

# --- 4. SUBMARINE (Size 3) ---
sub draw_submarine ( $self, $cr, $w, $h, %opts ) {
    my ( $x0, $y0 ) = ( 3, 3 );
    my $cw = $w - 6;
    my $ch = $h - 6;
    my $yc = $h / 2;
    my $r  = $ch * 0.45;

    # Rounded bulbous sonar bow to tapered stern
    $cr->arc( $x0 + $r, $yc, $r, $PI / 2, 3 * $PI / 2 );
    $cr->line_to( $x0 + $cw - 8, $yc - $r );
    $cr->curve_to( $x0 + $cw, $yc, $x0 + $cw, $yc, $x0 + $cw - 8, $yc + $r );
    $cr->close_path;

    if ( $opts{sunk} ) {
        $cr->set_source_rgb( 0.14, 0.18, 0.22 );
        $cr->fill_preserve;
        $cr->set_line_width(1.5);
        $cr->set_source_rgb( 0.7, 0.2, 0.2 );
        $cr->stroke;
        return;
    }

    $cr->set_source_rgb( 0.16, 0.24, 0.35 );
    $cr->fill_preserve;
    $cr->set_line_width(1.5);
    $cr->set_source_rgb( 0.32, 0.48, 0.66 );
    $cr->stroke;

    # Conning tower (sail)
    my $sx = $x0 + ( $cw * 0.48 );
    $cr->arc( $sx, $yc, $ch * 0.25, 0, 2 * $PI );
    $cr->set_source_rgb( 0.22, 0.32, 0.46 );
    $cr->fill_preserve;
    $cr->set_line_width(1);
    $cr->set_source_rgb( 0.5, 0.7, 0.9 );
    $cr->stroke;

    # Periscope mast
    $cr->move_to( $sx, $yc );
    $cr->line_to( $sx, $y0 - 1 );
    $cr->stroke;
    return;
}

# --- 5. DESTROYER (Size 2) ---
sub draw_destroyer ( $self, $cr, $w, $h, %opts ) {
    my ( $x0, $y0 ) = ( 3, 3 );
    my $cw = $w - 6;
    my $ch = $h - 6;
    my $yc = $h / 2;

    # Agile patrol boat wedge hull
    $cr->move_to( $x0, $yc );
    $cr->line_to( $x0 + 12,      $y0 );
    $cr->line_to( $x0 + $cw - 2, $y0 + 1 );
    $cr->line_to( $x0 + $cw,     $y0 + 3 );
    $cr->line_to( $x0 + $cw,     $y0 + $ch - 3 );
    $cr->line_to( $x0 + $cw - 2, $y0 + $ch - 1 );
    $cr->line_to( $x0 + 12,      $y0 + $ch );
    $cr->close_path;

    if ( $opts{sunk} ) {
        $cr->set_source_rgb( 0.18, 0.20, 0.22 );
        $cr->fill_preserve;
        $cr->set_line_width(1.5);
        $cr->set_source_rgb( 0.7, 0.2, 0.2 );
        $cr->stroke;
        return;
    }

    $cr->set_source_rgb( 0.38, 0.43, 0.50 );
    $cr->fill_preserve;
    $cr->set_line_width(1.5);
    $cr->set_source_rgb( 0.58, 0.65, 0.75 );
    $cr->stroke;

    # Bridge cabin
    my $bx = $x0 + ( $cw * 0.45 );
    $cr->rectangle( $bx, $yc - ( $ch * 0.25 ), $cw * 0.22, $ch * 0.50 );
    $cr->set_source_rgb( 0.45, 0.52, 0.60 );
    $cr->fill_preserve;
    $cr->set_line_width(1);
    $cr->set_source_rgb( 0.7, 0.8, 0.9 );
    $cr->stroke;

    # Forward gun mount
    my $tx = $x0 + ( $cw * 0.25 );
    $cr->arc( $tx, $yc, $ch * 0.20, 0, 2 * $PI );
    $cr->set_source_rgb( 0.26, 0.30, 0.36 );
    $cr->fill;
    $cr->set_line_width(1.5);
    $cr->set_source_rgb( 0.7, 0.8, 0.9 );
    $cr->move_to( $tx, $yc );
    $cr->line_to( $tx - ( $cw * 0.12 ), $yc );
    $cr->stroke;
    return;
}

sub draw_generic_hull ( $self, $cr, $w, $h, %opts ) {
    my ( $x0, $y0 ) = ( 3, 3 );
    my $cw = $w - 6;
    my $ch = $h - 6;
    my $yc = $h / 2;

    $cr->move_to( $x0, $yc );
    $cr->line_to( $x0 + 10,  $y0 );
    $cr->line_to( $x0 + $cw, $y0 );
    $cr->line_to( $x0 + $cw, $y0 + $ch );
    $cr->line_to( $x0 + 10,  $y0 + $ch );
    $cr->close_path;

    $cr->set_source_rgb( 0.35, 0.40, 0.48 );
    $cr->fill_preserve;
    $cr->set_line_width(1.5);
    $cr->set_source_rgb( 0.6, 0.7, 0.8 );
    $cr->stroke;
    return;
}

sub calc_ship_sweep_alpha ( $self, $ship, $cs, $progress = 0.0 ) {
    my $board_w = 10 * $cs;
    my $len     = $ship->length;
    my $ship_center_x =
      $ship->dir eq 'H'
      ? ( ( $ship->x - 1 ) + ( $len / 2 ) ) * $cs
      : ( ( $ship->x - 1 ) + 0.5 ) * $cs;

    my $beam_x = $progress * $board_w;
    my $dx     = $beam_x - $ship_center_x;
    $dx += $board_w if $dx < 0;

    my $dist_ratio = $dx / $board_w;

# Phosphor decay curve: maximum visibility (1.0) just after sweep line passes,
# decaying smoothly down toward floor of 0.20 with balanced persistence (decay constant 2.1).
    my $alpha = 0.05 + 0.95 * exp( -2.1 * $dist_ratio );
    $alpha = 1.00 if $alpha > 1.00;
    $alpha = 0.05 if $alpha < 0.05;

    return $alpha;
}

sub draw_radar_beam ( $self, $cr, $ox, $oy, $progress = 0.0 ) {
    my $cs      = $self->{cell_size};
    my $board_w = 10 * $cs;
    my $board_h = 10 * $cs;

    $cr->save;

    # Clip strictly to the 10x10 board grid bounds
    $cr->rectangle( $ox, $oy, $board_w, $board_h );
    $cr->clip;

    my $bx     = $ox + ( $progress * $board_w );
    my $tail_w = $board_w * 0.28;

    # 1. Trailing phosphor glow gradient
    if ( $bx - $tail_w >= $ox ) {
        my $pat = Cairo::LinearGradient->create( $bx - $tail_w, 0, $bx, 0 );
        $pat->add_color_stop_rgba( 0.0, 0.0, 0.85, 0.95, 0.00 );
        $pat->add_color_stop_rgba( 0.7, 0.0, 0.85, 0.95, 0.08 );
        $pat->add_color_stop_rgba( 1.0, 0.0, 0.85, 0.95, 0.24 );
        $cr->set_source($pat);
        $cr->rectangle( $bx - $tail_w, $oy, $tail_w, $board_h );
        $cr->fill;
    }
    else {
        # Beam is near left edge; tail wraps around from right edge
        my $head_tail_w = $bx - $ox;
        if ( $head_tail_w > 0 ) {
            my $pat1 =
              Cairo::LinearGradient->create( $bx - $tail_w, 0, $bx, 0 );
            $pat1->add_color_stop_rgba( 0.0, 0.0, 0.85, 0.95, 0.00 );
            $pat1->add_color_stop_rgba( 0.7, 0.0, 0.85, 0.95, 0.08 );
            $pat1->add_color_stop_rgba( 1.0, 0.0, 0.85, 0.95, 0.24 );
            $cr->set_source($pat1);
            $cr->rectangle( $ox, $oy, $head_tail_w, $board_h );
            $cr->fill;
        }

        my $wrap_w     = $tail_w - $head_tail_w;
        my $wrap_start = ( $ox + $board_w ) - $wrap_w;
        my $pat2 = Cairo::LinearGradient->create( $bx - $tail_w + $board_w,
            0, $bx + $board_w, 0 );
        $pat2->add_color_stop_rgba( 0.0, 0.0, 0.85, 0.95, 0.00 );
        $pat2->add_color_stop_rgba( 0.7, 0.0, 0.85, 0.95, 0.08 );
        $pat2->add_color_stop_rgba( 1.0, 0.0, 0.85, 0.95, 0.24 );
        $cr->set_source($pat2);
        $cr->rectangle( $wrap_start, $oy, $wrap_w, $board_h );
        $cr->fill;
    }

    # 2. Outer beam glow
    $cr->set_line_width(3.5);
    $cr->set_source_rgba( 0.15, 0.90, 1.00, 0.40 );
    $cr->move_to( $bx, $oy );
    $cr->line_to( $bx, $oy + $board_h );
    $cr->stroke;

    # 3. High-intensity sharp core beam line
    $cr->set_line_width(1.5);
    $cr->set_source_rgba( 0.75, 1.00, 1.00, 0.95 );
    $cr->move_to( $bx, $oy );
    $cr->line_to( $bx, $oy + $board_h );
    $cr->stroke;

    $cr->restore;
    return;
}

1;


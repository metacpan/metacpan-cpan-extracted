package Gtk3::ImageView::Tool::Selector;

use warnings;
use strict;
use base 'Gtk3::ImageView::Tool';
use Glib qw(TRUE FALSE);    # To get TRUE and FALSE
use List::Util qw(min);
use Readonly;
Readonly my $CURSOR_PIXELS => 5;
Readonly my $RIGHT_BUTTON  => 3;

our $VERSION = 9;

my %cursorhash = (
    lower => {
        lower => 'nw-resize',
        mid   => 'w-resize',
        upper => 'sw-resize',
    },
    mid => {
        lower => 'n-resize',
        mid   => 'crosshair',
        upper => 's-resize',
    },
    upper => {
        lower => 'ne-resize',
        mid   => 'e-resize',
        upper => 'se-resize',
    },
);

sub button_pressed {
    my $self  = shift;
    my $event = shift;

    # Don't block context menu
    if ( $event->button == $RIGHT_BUTTON ) {
        return FALSE;
    }

    $self->{drag_start} = { x => undef, y => undef };
    $self->{dragging}   = TRUE;
    $self->view->update_cursor( $event->x, $event->y );
    $self->_update_selection($event);
    return TRUE;
}

sub button_released {
    my $self  = shift;
    my $event = shift;
    $self->{dragging} = FALSE;
    $self->view->update_cursor( $event->x, $event->y );
    $self->_update_selection($event);
    return;
}

sub motion {
    my $self  = shift;
    my $event = shift;
    if ( not $self->{dragging} ) { return FALSE }
    $self->_update_selection($event);
    return;
}

sub _update_selection {
    my ( $self, $event ) = @_;
    my ( $x, $y, $x2, $y2, $x_old, $y_old, $x2_old, $y2_old );
    if ( not defined $self->{h_edge} ) { $self->{h_edge} = 'mid' }
    if ( not defined $self->{v_edge} ) { $self->{v_edge} = 'mid' }
    if ( $self->{h_edge} eq 'lower' ) {
        $x  = $event->x;
        $x2 = $self->{drag_start}{x};
    }
    elsif ( $self->{h_edge} eq 'upper' ) {
        $x  = $self->{drag_start}{x};
        $x2 = $event->x;
    }
    if ( $self->{v_edge} eq 'lower' ) {
        $y  = $event->y;
        $y2 = $self->{drag_start}{y};
    }
    elsif ( $self->{v_edge} eq 'upper' ) {
        $y  = $self->{drag_start}{y};
        $y2 = $event->y;
    }
    if ( $self->{h_edge} eq 'mid' and $self->{v_edge} eq 'mid' ) {
        $x  = $self->{drag_start}{x};
        $y  = $self->{drag_start}{y};
        $x2 = $event->x;
        $y2 = $event->y;
    }
    else {
        my $selection = $self->view->get_selection;
        if ( not defined $x or not defined $y ) {
            ( $x_old, $y_old ) =
              $self->view->to_widget_coords( $selection->{x}, $selection->{y} );
        }
        if ( not defined $x2 or not defined $y2 ) {
            ( $x2_old, $y2_old ) = $self->view->to_widget_coords(
                $selection->{x} + $selection->{width},
                $selection->{y} + $selection->{height}
            );
        }
        if ( not defined $x ) {
            $x = $x_old;
        }
        if ( not defined $x2 ) {
            $x2 = $x2_old;
        }
        if ( not defined $y ) {
            $y = $y_old;
        }
        if ( not defined $y2 ) {
            $y2 = $y2_old;
        }
    }
    my ( $w, $h ) =
      $self->view->to_image_distance( abs $x2 - $x, abs $y2 - $y );
    ( $x, $y ) =
      $self->view->to_image_coords( min( $x, $x2 ), min( $y, $y2 ) );
    $self->view->set_selection(
        {
            x      => int( $x + 0.5 ),
            y      => int( $y + 0.5 ),
            width  => int( $w + 0.5 ),
            height => int( $h + 0.5 )
        }
    );
    return;
}

sub cursor_type_at_point {
    my ( $self, $x, $y ) = @_;

    my $selection = $self->view->get_selection;
    if ( defined $selection ) {
        my ( $sx1, $sy1 ) =
          $self->view->to_widget_coords( $selection->{x}, $selection->{y} );
        my ( $sx2, $sy2 ) = $self->view->to_widget_coords(
            $selection->{x} + $selection->{width},
            $selection->{y} + $selection->{height}
        );

        # If we are dragging, a corner cursor must stay as a corner cursor,
        # a left/right cursor must stay as left/right,
        # and a top/bottom cursor must stay as top/bottom
        if ( $self->{dragging} ) {
            $self->_update_dragged_edge( 'x', $x, $sx1, $sx2 );
            $self->_update_dragged_edge( 'y', $y, $sy1, $sy2 );
            if ( $self->{h_edge} eq 'mid' ) {
                if ( $self->{v_edge} eq 'mid' ) {
                    $self->{h_edge}     = 'upper';
                    $self->{v_edge}     = 'upper';
                    $self->{drag_start} = { x => $x, y => $y };
                }
                else {
                    if ( not defined $self->{drag_start}{x} ) {
                        $self->{drag_start}{x} =
                          $self->{v_edge} eq 'lower' ? $sx2 : $sx1;
                    }
                }
            }
            elsif ( $self->{v_edge} eq 'mid' ) {
                if ( not defined $self->{drag_start}{y} ) {
                    $self->{drag_start}{y} =
                      $self->{h_edge} eq 'lower' ? $sy2 : $sy1;
                }
            }
        }
        else {
            $self->_update_undragged_edge( 'h_edge', $x, $y, $sx1, $sy1, $sx2,
                $sy2 );
            $self->_update_undragged_edge( 'v_edge', $y, $x, $sy1, $sx1, $sy2,
                $sx2 );
        }
    }
    else {
        if ( $self->{dragging} ) {
            $self->{drag_start} = { x => $x, y => $y };
            ( $self->{h_edge}, $self->{v_edge} ) = qw( upper upper );
        }
        else {
            ( $self->{h_edge}, $self->{v_edge} ) = qw( mid mid );
        }
    }
    return $cursorhash{ $self->{h_edge} }{ $self->{v_edge} };
}

sub _update_dragged_edge {
    my ( $self, $direction, $s, $s1, $s2 ) = @_;
    my $edge = ( $direction eq 'x' ? 'h' : 'v' ) . '_edge';
    if ( $self->{$edge} eq 'lower' ) {
        if ( defined $self->{drag_start}{$direction} ) {
            if ( $s > $self->{drag_start}{$direction} ) {
                $self->{$edge} = 'upper';
            }
            else {
                $self->{$edge} = 'lower';
            }
        }
        else {
            $self->{drag_start}{$direction} = $s2;
            $self->{$edge} = 'lower';
        }
    }
    elsif ( $self->{$edge} eq 'upper' ) {
        if ( defined $self->{drag_start}{$direction} ) {
            if ( $s < $self->{drag_start}{$direction} ) {
                $self->{$edge} = 'lower';
            }
            else {
                $self->{$edge} = 'upper';
            }
        }
        else {
            $self->{drag_start}{$direction} = $s1;
            $self->{$edge} = 'upper';
        }
    }
    return;
}

sub _update_undragged_edge {
    my ( $self, $edge, @coords ) = @_;
    my ( $x, $y, $sx1, $sy1, $sx2, $sy2 ) = @coords;
    $self->{$edge} = 'mid';
    if ( _between( $y, $sy1, $sy2 ) ) {
        if ( _between( $x, $sx1 - $CURSOR_PIXELS, $sx1 + $CURSOR_PIXELS ) ) {
            $self->{$edge} = 'lower';
        }
        elsif ( _between( $x, $sx2 - $CURSOR_PIXELS, $sx2 + $CURSOR_PIXELS ) ) {
            $self->{$edge} = 'upper';
        }
    }
    return;
}

sub _between {
    my ( $value, $lower, $upper ) = @_;
    return ( $value > $lower and $value < $upper );
}

# compatibility layer

sub get_selection {
    my $self = shift;
    return $self->view->get_selection;
}

sub set_selection {
    my ( $self, @args ) = @_;
    $self->view->set_selection(@args);
    return;
}

1;

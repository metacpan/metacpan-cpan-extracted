package Gtk3::ImageView::Tool::Selector;

use warnings;
use strict;
use base 'Gtk3::ImageView::Tool';
use POSIX qw(round);
use Glib qw(TRUE FALSE);    # To get TRUE and FALSE
use List::Util qw(min);
use Readonly;
Readonly my $CURSOR_PIXELS => 5;
Readonly my $RIGHT_BUTTON  => 3;

our $VERSION = 1;

my %cursorhash = (
    left => {
        top    => 'nw-resize',
        mid    => 'w-resize',
        bottom => 'sw-resize',
    },
    mid => {
        top    => 'n-resize',
        mid    => 'crosshair',
        bottom => 's-resize',
    },
    right => {
        top    => 'ne-resize',
        mid    => 'e-resize',
        bottom => 'se-resize',
    },
);

sub button_pressed {
    my $self  = shift;
    my $event = shift;

    # Don't block context menu
    if ( $event->button == $RIGHT_BUTTON ) {
        return FALSE;
    }

    $self->{drag_start} = { x => $event->x, y => $event->y };
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
    if ( $self->{h_edge} eq 'left' ) {
        $x = $event->x;
    }
    elsif ( $self->{h_edge} eq 'right' ) {
        $x2 = $event->x;
    }
    if ( $self->{v_edge} eq 'top' ) {
        $y = $event->y;
    }
    elsif ( $self->{v_edge} eq 'bottom' ) {
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
            x      => round($x),
            y      => round($y),
            width  => round($w),
            height => round($h)
        }
    );
    return;
}

sub cursor_type_at_point {
    my ( $self, $x, $y ) = @_;

    # If we are dragging, don't change the cursor, as we want to continue
    # to drag the corner or edge or mid element we started dragging.
    if ( $self->{dragging} ) { return }
    ( $self->{h_edge}, $self->{v_edge} ) = qw( mid mid );
    my $selection = $self->view->get_selection;
    if ( defined $selection ) {
        my ( $sx1, $sy1 ) =
          $self->view->to_widget_coords( $selection->{x}, $selection->{y} );
        my ( $sx2, $sy2 ) = $self->view->to_widget_coords(
            $selection->{x} + $selection->{width},
            $selection->{y} + $selection->{height}
        );
        if ( _between( $x, $sx1 - $CURSOR_PIXELS, $sx1 + $CURSOR_PIXELS ) ) {
            $self->{h_edge} = 'left';
        }
        elsif ( _between( $x, $sx2 - $CURSOR_PIXELS, $sx2 + $CURSOR_PIXELS ) ) {
            $self->{h_edge} = 'right';
        }
        if ( _between( $y, $sy1 - $CURSOR_PIXELS, $sy1 + $CURSOR_PIXELS ) ) {
            $self->{v_edge} = 'top';
        }
        elsif ( _between( $y, $sy2 - $CURSOR_PIXELS, $sy2 + $CURSOR_PIXELS ) ) {
            $self->{v_edge} = 'bottom';
        }
    }
    return $cursorhash{ $self->{h_edge} }{ $self->{v_edge} };
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

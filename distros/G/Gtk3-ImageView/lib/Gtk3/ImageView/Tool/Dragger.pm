package Gtk3::ImageView::Tool::Dragger;

use warnings;
use strict;
use base 'Gtk3::ImageView::Tool';
use Glib qw(TRUE FALSE);    # To get TRUE and FALSE
use Readonly;
Readonly my $FLOAT_EPS    => 0.01;
Readonly my $RIGHT_BUTTON => 3;

our $VERSION = '11';

sub button_pressed {
    my $self  = shift;
    my $event = shift;

    # Don't block context menu
    if ( $event->button == $RIGHT_BUTTON ) {
        return FALSE;
    }

    $self->{drag_start}   = { x => $event->x, y => $event->y };
    $self->{dnd_start}    = { x => $event->x, y => $event->y };
    $self->{dnd_eligible} = TRUE;
    $self->{dragging}     = TRUE;
    $self->{button}       = $event->button;
    $self->view->update_cursor( $event->x, $event->y );
    return TRUE;
}

sub button_released {
    my $self  = shift;
    my $event = shift;
    $self->{dragging} = FALSE;
    $self->view->update_cursor( $event->x, $event->y );
    return;
}

sub motion {
    my $self  = shift;
    my $event = shift;
    if ( not $self->{dragging} ) { return FALSE }
    my $offset = $self->view->get_offset;
    my $zoom   = $self->view->get_zoom;
    my $ratio  = $self->view->get_resolution_ratio;
    my $offset_x =
      $offset->{x} + ( $event->x - $self->{drag_start}{x} ) / $zoom * $ratio;
    my $offset_y =
      $offset->{y} + ( $event->y - $self->{drag_start}{y} ) / $zoom;
    ( $self->{drag_start}{x}, $self->{drag_start}{y} ) =
      ( $event->x, $event->y );
    $self->view->set_offset( $offset_x, $offset_y );
    my $new_offset = $self->view->get_offset;

    if ( not $self->{dnd_eligible} ) {
        return;
    }

    if (    _approximately( $new_offset->{x}, $offset_x )
        and _approximately( $new_offset->{y}, $offset_y ) )
    {
        # If there was a movement in the image, disable start of dnd until
        # mouse button is pressed again
        $self->{dnd_eligible} = FALSE;
        return;
    }

    # movement was clamped because of the edge, but did mouse move far enough?
    if (
        $self->view->drag_check_threshold(
            $self->{dnd_start}{x}, $self->{dnd_start}{y},
            $event->x,             $event->y
        )
        and $self->view->signal_emit(
            'dnd-start', $event->x, $event->y, $self->{button}
        )
      )
    {
        $self->{dragging} = FALSE;
    }
    return;
}

sub _approximately {
    my ( $a, $b ) = @_;
    return abs( $a - $b ) < $FLOAT_EPS;
}

sub cursor_type_at_point {
    my ( $self, $x, $y ) = @_;
    ( $x, $y ) = $self->view->to_image_coords( $x, $y );
    my $pixbuf_size = $self->view->get_pixbuf_size;
    if (    $x > 0
        and $x < $pixbuf_size->{width}
        and $y > 0
        and $y < $pixbuf_size->{height} )
    {
        if ( $self->{dragging} ) {
            return 'grabbing';
        }
        else {
            return 'grab';
        }
    }
    return;
}

1;

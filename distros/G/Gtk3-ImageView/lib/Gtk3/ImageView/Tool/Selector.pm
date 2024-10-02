package Gtk3::ImageView::Tool::Selector;

use warnings;
use strict;
use base 'Gtk3::ImageView::Tool';
use Glib       qw(TRUE FALSE);    # To get TRUE and FALSE
use List::Util qw(min);
use Readonly;
Readonly my $RIGHT_BUTTON => 3;
Readonly my $EDGE_WIDTH   => 5;

our $VERSION = '11';

sub button_pressed {
    my ( $self, $event ) = @_;
    if ( $event->button == $RIGHT_BUTTON ) {
        return FALSE;
    }
    my $type = $self->cursor_type_at_point( $event->x, $event->y );
    if ( $type eq 'grab' ) {
        $type                 = 'grabbing';
        $self->{drag_start_x} = int( $event->x + 0.5 );
        $self->{drag_start_y} = int( $event->y + 0.5 );
    }
    $self->{dragging} = $type;
    $self->_update_selection( $event->x, $event->y );
    return FALSE;
}

sub button_released {
    my ( $self, $event ) = @_;
    if ( $event->button == $RIGHT_BUTTON ) {
        return FALSE;
    }
    if ( $self->{dragging} ) {
        $self->_update_selection( $event->x, $event->y );
    }
    $self->{dragging} = undef;
    $self->view->update_cursor( $event->x, $event->y );
    return FALSE;
}

sub motion {
    my ( $self, $event ) = @_;
    if ( $self->{dragging} ) {
        $self->_update_selection( $event->x, $event->y );
    }
    return FALSE;
}

sub cursor_type_at_point {    ## no critic (ProhibitExcessComplexity);
    my ( $self, $x, $y ) = @_;
    if ( $self->{dragging} ) {
        return $self->{dragging};
    }
    my $selection = $self->view->get_selection;
    if ( !defined $selection ) {
        return 'crosshair';
    }
    my $edge_width = $EDGE_WIDTH * $self->view->get('scale-factor');
    my ( $sx1, $sy1 ) =
      $self->view->to_widget_coords( $selection->{x}, $selection->{y} );
    my ( $sx2, $sy2 ) = $self->view->to_widget_coords(
        $selection->{x} + $selection->{width},
        $selection->{y} + $selection->{height}
    );
    if (   $x < $sx1 - $edge_width
        || $x > $sx2 + $edge_width
        || $y < $sy1 - $edge_width
        || $y > $sy2 + $edge_width )
    {
        return 'crosshair';
    }
    if (   $x > $sx1 + $edge_width
        && $x < $sx2 - $edge_width
        && $y > $sy1 + $edge_width
        && $y < $sy2 - $edge_width )
    {
        return 'grab';
    }

# This makes it possible for the selection to be smaller than edge_width and still be resizeable in all directions
    my $leftish = $x < ( $sx1 + $sx2 ) / 2;
    my $topish  = $y < ( $sy1 + $sy2 ) / 2;
    if ( $y > $sy1 + $edge_width && $y < $sy2 - $edge_width ) {
        if ($leftish) {
            return 'w-resize';
        }
        else {
            return 'e-resize';
        }
    }
    if ( $x > $sx1 + $edge_width && $x < $sx2 - $edge_width ) {
        if ($topish) {
            return 'n-resize';
        }
        else {
            return 's-resize';
        }
    }
    if ($leftish) {
        if ($topish) {
            return 'nw-resize';
        }
        else {
            return 'sw-resize';
        }
    }
    else {
        if ($topish) {
            return 'ne-resize';
        }
        else {
            return 'se-resize';
        }
    }
}

sub _update_selection {
    my ( $self, $x, $y ) = @_;
    my $selection = $self->view->get('selection-float') // {
        x      => 0,
        y      => 0,
        width  => 0,
        height => 0,
    };
    my ( $sel_x1, $sel_y1 ) =
      $self->view->to_widget_coords( $selection->{x}, $selection->{y} );
    my ( $sel_x2, $sel_y2 ) = $self->view->to_widget_coords(
        $selection->{x} + $selection->{width},
        $selection->{y} + $selection->{height}
    );
    my $type = $self->{dragging};
    if ( $type eq 'grabbing' ) {
        my $off_x = $x - $self->{drag_start_x};
        my $off_y = $y - $self->{drag_start_y};
        $sel_x1 += $off_x;
        $sel_x2 += $off_x;
        $sel_y1 += $off_y;
        $sel_y2 += $off_y;
        $self->{drag_start_x} = $x;
        $self->{drag_start_y} = $y;
    }
    if ( $type eq 'crosshair' ) {
        $sel_x1 = $x;
        $sel_x2 = $x;
        $sel_y1 = $y;
        $sel_y2 = $y;
        $type   = 'se-resize';
    }
    my $flip_we = 0;
    my $flip_ns = 0;
    if ( $type =~ /w-resize/smx ) {
        $sel_x1 = $x;
        if ( $x > $sel_x2 ) { $flip_we = 'e' }
    }
    if ( $type =~ /e-resize/smx ) {
        $sel_x2 = $x;
        if ( $x < $sel_x1 ) { $flip_we = 'w' }
    }
    if ( $type =~ /n.?-resize/smx ) {
        $sel_y1 = $y;
        if ( $y > $sel_y2 ) { $flip_ns = 's' }
    }
    if ( $type =~ /s.?-resize/smx ) {
        $sel_y2 = $y;
        if ( $y < $sel_y1 ) { $flip_ns = 'n' }
    }
    my ( $w, $h ) = $self->view->to_image_distance( abs( $sel_x2 - $sel_x1 ),
        abs( $sel_y2 - $sel_y1 ) );
    my ( $img_x, $img_y ) =
      $self->view->to_image_coords( min( $sel_x1, $sel_x2 ),
        min( $sel_y1, $sel_y2 ) );
    $self->view->set_selection(
        {
            x      => $img_x,
            y      => $img_y,
            width  => $w,
            height => $h,
        }
    );

    # Prepare for next mouse event
    # If we are dragging, a corner cursor must stay as a corner cursor,
    # a left/right cursor must stay as left/right,
    # and a top/bottom cursor must stay as top/bottom
    if ($flip_we) {
        $type =~ s/[we]-/$flip_we-/smx;
    }
    if ($flip_ns) {
        $type =~ s/^[ns]/$flip_ns/smx;
    }
    $self->{dragging} = $type;
    $self->view->update_cursor( $x, $y );
    return;
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

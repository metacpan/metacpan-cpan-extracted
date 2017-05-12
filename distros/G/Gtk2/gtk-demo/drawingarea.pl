#!/usr/bin/perl -w
#
# Drawing Area
#
# GtkDrawingArea is a blank area where you can draw custom displays
# of various kinds.
#
# This demo has two drawing areas. The checkerboard area shows
# how you can just draw something; all you have to do is write
# a signal handler for expose_event, as shown here.
#
# The "scribble" area is a bit more advanced, and shows how to handle
# events such as button presses and mouse motion. Click the mouse
# and drag in the scribble area to draw squiggles. Resize the window
# to clear the area.
#

package drawingarea;

use Glib qw(TRUE FALSE);
use Gtk2;


my $window = undef;
# Pixmap for scribble area, to store current scribbles
my $pixmap = undef;

# Create a new pixmap of the appropriate size to store our scribbles
sub scribble_configure_event {
  my ($widget, $event, $data) = @_;

  # get rid of the old one
  $pixmap = undef if $pixmap;

  $pixmap = Gtk2::Gdk::Pixmap->new ($widget->window,
                                    $widget->allocation->width,
                                    $widget->allocation->height,
                                    -1);

  # Initialize the pixmap to white
  $pixmap->draw_rectangle ($widget->style->white_gc,
                           TRUE,
                           0, 0,
                           $widget->allocation->width,
                           $widget->allocation->height);

  # We've handled the configure event, no need for further processing.
  return TRUE;
}

# Redraw the screen from the pixmap
sub scribble_expose_event {
  my ($widget, $event, $data) = @_;
  #
  # We use the "foreground GC" for the widget since it already exists,
  # but honestly any GC would work. The only thing to worry about
  # is whether the GC has an inappropriate clip region set.
  #
  $widget->window->draw_drawable ($widget->style->fg_gc($widget->state),
                                  $pixmap,
                                  # Only copy the area that was exposed.
                                  $event->area->x, $event->area->y,
                                  $event->area->x, $event->area->y,
                                  $event->area->width, $event->area->height);
  
  return FALSE;
}

# Draw a rectangle on the screen
sub draw_brush {
  my ($widget, $x, $y) = @_;
  my $update_rect = Gtk2::Gdk::Rectangle->new ($x - 3, $y - 3, 6, 6);

  # Paint to the pixmap, where we store our state
  $pixmap->draw_rectangle ($widget->style->black_gc,
                           TRUE,
			   $update_rect->values);
#                           $update_rect->x,
#                           $update_rect->y,
#                           $update_rect->width,
#                           $update_rect->height);

  # Now invalidate the affected region of the drawing area.
#  $widget->window->invalidate_rect (\@update_rect, FALSE);
#  use Data::Dumper;
#  warn Dumper($update_rect);
  $widget->window->invalidate_rect ($update_rect, FALSE);
}

sub scribble_button_press_event {
  my ($widget, $event, $data) = @_;

  return FALSE unless defined $pixmap;
    # paranoia check, in case we haven't gotten a configure event
  
  if ($event->button == 1) {
    draw_brush ($widget, $event->x, $event->y);
  }

  # We've handled the event, stop processing
  return TRUE;
}

sub scribble_motion_notify_event {
  my ($widget, $event, $data) = @_;

  return FALSE unless defined $pixmap;
    # paranoia check, in case we haven't gotten a configure event

  #
  # This call is very important; it requests the next motion event.
  # If you don't call gdk_window_get_pointer() you'll only get
  # a single motion event. The reason is that we specified
  # GDK_POINTER_MOTION_HINT_MASK to gtk_widget_set_events().
  # If we hadn't specified that, we could just use event->x, event->y
  # as the pointer location. But we'd also get deluged in events.
  # By requesting the next event as we handle the current one,
  # we avoid getting a huge number of events faster than we
  # can cope.
  #
  
  my (undef, $x, $y, $state) = $event->window->get_pointer;
    
#  if (state & GDK_BUTTON1_MASK)
#  if (grep 'button1-mask', @$state) {
  if (grep (/button1-mask/, @$state)) {
    draw_brush ($widget, $x, $y);
  }

  # We've handled it, stop processing
  return TRUE;
}

my $color;

sub checkerboard_expose {
  my ($da, $event, $data) = @_;
  
use constant CHECK_SIZE => 10;
use constant SPACING => 2;
  
  #
  # At the start of an expose handler, a clip region of event->area
  # is set on the window, and event->area has been cleared to the
  # widget's background color. The docs for
  # gdk_window_begin_paint_region() give more details on how this
  # works.
  #

  # It would be a bit more efficient to keep these
  # GCs around instead of recreating on each expose, but
  # this is the lazy/slow way.
  #
  my $gc1 = Gtk2::Gdk::GC->new ($da->window);
  my $color = Gtk2::Gdk::Color->new (30000, 0, 30000);
#  my $color = Gtk2::Gdk::Color->parse ('purple');
  $gc1->set_rgb_fg_color ($color);

  my $gc2 = Gtk2::Gdk::GC->new ($da->window);
#  $color = Gtk2::Gdk::Color->new (65535, 65535, 65535);
  $color = Gtk2::Gdk::Color->parse ('white');
  $gc2->set_rgb_fg_color ($color);
  
  my $xcount = 0;
  my $i = SPACING;
  while ($i < $da->allocation->width) {
      my $j = SPACING;
      my $ycount = $xcount % 2; # start with even/odd depending on row
      while ($j < $da->allocation->height) {

          #
	  # If we're outside event->area, this will do nothing.
	  # It might be mildly more efficient if we handled
	  # the clipping ourselves, but again we're feeling lazy.
	  #
	  $da->window->draw_rectangle ($ycount % 2 ? $gc1 : $gc2,
                                       TRUE,
                                       $i, $j,
                                       CHECK_SIZE,
                                       CHECK_SIZE);

	  $j += CHECK_SIZE + SPACING;
	  ++$ycount;
	}

      $i += CHECK_SIZE + SPACING;
      ++$xcount;
    }
  
#  g_object_unref (gc1);
#  g_object_unref (gc2);
  
  #
  # return TRUE because we've handled this event, so no
  # further processing is required.
  #
  return TRUE;
}

sub do {
  if (!$window) {
      $window = Gtk2::Window->new;
      $window->set_title ("Drawing Area");

      $window->signal_connect (destroy => sub { $window = undef; 1 });

      $window->set_border_width (8);

      my $vbox = Gtk2::VBox->new (FALSE, 8);
      $vbox->set_border_width (8);
      $window->add ($vbox);

      #
      # Create the checkerboard area
      #

      my $label = Gtk2::Label->new;
      $label->set_markup ("<u>Checkerboard pattern</u>");
      $vbox->pack_start ($label, FALSE, FALSE, 0);
      
      my $frame = Gtk2::Frame->new;
      $frame->set_shadow_type ('in');
      $vbox->pack_start ($frame, TRUE, TRUE, 0);
      
      my $da = Gtk2::DrawingArea->new;
      # set a minimum size
      $da->set_size_request (100, 100);

      $frame->add ($da);

      $da->signal_connect (expose_event => \&checkerboard_expose);

      #
      # Create the scribble area
      #

      $label = Gtk2::Label->new;
      $label->set_markup ("<u>Scribble area</u>");
      $vbox->pack_start ($label, FALSE, FALSE, 0);
      
      $frame = Gtk2::Frame->new;
      $frame->set_shadow_type ('in');
      $vbox->pack_start ($frame, TRUE, TRUE, 0);

      $da = Gtk2::DrawingArea->new;
      # set a minimum size
      $da->set_size_request (100, 100);

      $frame->add ($da);

      # Signals used to handle backing pixmap
      
      $da->signal_connect (expose_event => \&scribble_expose_event);
      $da->signal_connect (configure_event => \&scribble_configure_event);
      
      # Event signals
      
      $da->signal_connect (motion_notify_event => \&scribble_motion_notify_event);
      $da->signal_connect (button_press_event => \&scribble_button_press_event);

      #
      # Ask to receive events the drawing area doesn't normally
      # subscribe to
      #
      $da->set_events ([ @{ $da->get_events },
##                         'exposure-mask',
                         'leave-notify-mask',
                         'button-press-mask',
                         'pointer-motion-mask',
                         'pointer-motion-hint-mask', ]);
    }

  if (!$window->visible) {
      $window->show_all;
  } else {	 
      $window->destroy;
      $window = undef;
  }

  return $window;
}

1;
__END__
Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.

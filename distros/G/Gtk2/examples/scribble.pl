#!/usr/bin/perl -w

#
# GTK - The GIMP Toolkit
# Copyright (C) 1995-1997 Peter Mattis, Spencer Kimball and Josh MacDonald
#
# Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the full
# list)
# 
# This library is free software; you can redistribute it and/or modify it under
# the terms of the GNU Library General Public License as published by the Free
# Software Foundation; either version 2.1 of the License, or (at your option)
# any later version.
# 
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for
# more details.
# 
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
#
# $Id$
#

# this was originally gtk-2.2.0/examples/scribble-simple/scribble-simple.c
# ported to gtk2-perl by muppet

use strict;
use Glib qw/TRUE FALSE/;
use Gtk2;

# Backing pixmap for drawing area
my $pixmap = undef;

# Create a new backing pixmap of the appropriate size
sub configure_event {
  my $widget = shift; # GtkWidget         *widget
  my $event  = shift; # GdkEventConfigure *event

  $pixmap = Gtk2::Gdk::Pixmap->new ($widget->window,
                                    $widget->allocation->width,
                                    $widget->allocation->height,
                                    -1);
  $pixmap->draw_rectangle ($widget->style->white_gc,
                           TRUE,
                           0, 0,
                           $widget->allocation->width,
                           $widget->allocation->height);

  return TRUE;
}

# Redraw the screen from the backing pixmap
sub expose_event {
  my $widget = shift; # GtkWidget      *widget
  my $event  = shift; # GdkEventExpose *event

  $widget->window->draw_drawable (
		     $widget->style->fg_gc($widget->state),
		     $pixmap,
		     $event->area->x, $event->area->y,
		     $event->area->x, $event->area->y,
		     $event->area->width, $event->area->height);

  return FALSE;
}

# Draw a rectangle on the screen
sub draw_brush {
  my ($widget, $x, $y) = @_;

  # this is not a real GdkRectangle structure; we don't actually need one.
  my @update_rect;
  $update_rect[0] = $x - 5;
  $update_rect[1] = $y - 5;
  $update_rect[2] = 10;
  $update_rect[3] = 10;
  $pixmap->draw_rectangle ($widget->style->black_gc,
                           TRUE, @update_rect);
  
  $widget->queue_draw_area (@update_rect);
}

sub button_press_event {
  my $widget = shift;	# GtkWidget      *widget
  my $event = shift;	# GdkEventButton *event

  if ($event->button == 1 && defined $pixmap) {
    draw_brush ($widget, $event->coords);
  }
  return TRUE;
}

sub motion_notify_event {
  my $widget = shift; # GtkWidget *widget
  my $event  = shift; # GdkEventMotion *event

  my ($x, $y, $state);

  if ($event->is_hint) {
    (undef, $x, $y, $state) = $event->window->get_pointer;
  } else {
    $x = $event->x;
    $y = $event->y;
    $state = $event->state;
  }

  if ($state >= "button1-mask" && defined $pixmap) {
    draw_brush ($widget, $x, $y);
  }
  
  return TRUE;
}

{
  Gtk2->init;

  my $window = Gtk2::Window->new ('toplevel');
  $window->set_name ("Test Input");

  my $vbox = Gtk2::VBox->new (FALSE, 0);
  $window->add ($vbox);
  $vbox->show;

  $window->signal_connect ("destroy", sub { exit(0); });

  # Create the drawing area

  my $drawing_area = Gtk2::DrawingArea->new;
  $drawing_area->set_size_request (200, 200);
  $vbox->pack_start ($drawing_area, TRUE, TRUE, 0);

  $drawing_area->show;

  # Signals used to handle backing pixmap

  $drawing_area->signal_connect (expose_event => \&expose_event);
  $drawing_area->signal_connect (configure_event => \&configure_event);

  # Event signals

  $drawing_area->signal_connect (motion_notify_event => \&motion_notify_event);
  $drawing_area->signal_connect (button_press_event => \&button_press_event);

  $drawing_area->set_events ([qw/exposure-mask
			         leave-notify-mask
			         button-press-mask
			         pointer-motion-mask
			         pointer-motion-hint-mask/]);

  # .. And a quit button
  my $button = Gtk2::Button->new ("Quit");
  $vbox->pack_start ($button, FALSE, FALSE, 0);

  $button->signal_connect_swapped (clicked => sub { $_[0]->destroy; }, $window);
  $button->show;

  $window->show;

  Gtk2->main;
}


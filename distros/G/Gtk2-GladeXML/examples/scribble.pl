#!/usr/bin/perl -w

#----------------------------------------------------------------------
# scribble.pl
#
# Muppet's Gtk2-perl example ported to use GladeXML
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
# 
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#  
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the
#  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#  Boston, MA 02111-1307, USA.
#
#----------------------------------------------------------------------

use strict;
use warnings;

use Gtk2 '-init'; # auto-initializes Gtk2
use Gtk2::GladeXML;
use Data::Dumper;

$Data::Dumper::Indent = 3;
use constant TRUE => 1;
use constant FALSE => 0;

my $glade;
my $window;
my $pixmap;
my $drawing_area;

# Load the UI from the Glade-2 file
$glade = Gtk2::GladeXML->new("scribble.glade");

# Connect the signal handlers
$glade->signal_autoconnect_from_package('main');

# Cache controls in perl-variables
$window = $glade->get_widget('main');
$drawing_area = $glade->get_widget('drawing_area');

$drawing_area->add_events ([qw/exposure-mask
			       leave-notify-mask
			       button-press-mask
			       button-release-mask
			       pointer-motion-mask
			       pointer-motion-hint-mask/]);
# Start it up
Gtk2->main;

exit 0;

#----------------------------------------------------------------------
# Signal handlers, connected to signals defined in the glade file

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


sub button_press_event {
  my $widget = shift;	# GtkWidget      *widget
  my $event = shift;	# GdkEventButton *event

  if ($event->button == 1 && defined $pixmap) {
    draw_brush ($widget, $event->coords);
  }
  return TRUE;
}

sub expose_event {
  my $widget = shift;	# GtkWidget      *widget
  my $event = shift;	# GdkEventButton *event

  # for some reason, configure_event doesn't get called on this widget
  # when the window is made visible in the glade file.  let's force it.
  configure_event($widget) if not defined $pixmap;

  $drawing_area->window->draw_drawable (
		     $widget->style->fg_gc($widget->state),
		     $pixmap,
		     $event->area->x, $event->area->y,
		     $event->area->x, $event->area->y,
		     $event->area->width, $event->area->height);


    return 0;
}


# Handles window-manager-quit: shuts down gtk2 lib
sub on_main_destroy_event {Gtk2->main_quit;}

# Handles close-button quit
sub quit_clicked {on_main_destroy_event;}    


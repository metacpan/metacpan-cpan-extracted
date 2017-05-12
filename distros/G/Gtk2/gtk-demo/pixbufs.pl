#!/usr/bin/perl -w
#
# Pixbufs
#
# A GdkPixbuf represents an image, normally in RGB or RGBA format.
# Pixbufs are normally used to load files from disk and perform
# image scaling.
#
# This demo is not all that educational, but looks cool. It was written
# by Extreme Pixbuf Hacker Federico Mena Quintero. It also shows
# off how to use GtkDrawingArea to do a simple animation.
#
# Look at the Image demo for additional pixbuf usage examples.
#
#

package pixbufs;

use Glib qw(TRUE FALSE);
use Gtk2;
use strict;

chdir '../gtk-demo';

use constant FRAME_DELAY => 50;

use constant BACKGROUND_NAME => "background.jpg";

my @image_names = (
  "apple-red.png",
  "gnome-applets.png",
  "gnome-calendar.png",
  "gnome-foot.png",
  "gnome-gmush.png",
  "gnome-gimp.png",
  "gnome-gsame.png",
  "gnu-keys.png"
);

# demo window
my $window = undef;

# Current frame
my $frame;

# Background image
my $background;
my ($back_width, $back_height);

# Images
my @images;

# Widgets
my $da;

# Loads the images for the demo.
# croaks if anything goes wrong.
sub load_pixbufs {
  return TRUE if $background; # already loaded earlier

  # demo_find_file() looks in the the current directory first,
  # so you can run gtk-demo without installing GTK, then looks
  # in the location where the file is installed.
  #
  my $filename = main::demo_find_file (BACKGROUND_NAME);

  $background = Gtk2::Gdk::Pixbuf->new_from_file ($filename);

  $back_width = $background->get_width;
  $back_height = $background->get_height;

  foreach my $i (@image_names) {
      push @images, Gtk2::Gdk::Pixbuf->new_from_file (
	      		main::demo_find_file ($i));
  }

  return TRUE;
}

# Expose callback for the drawing area
sub expose_cb {
  my ($widget, $event) = @_;

  # the C code that this replaces used gdk_pixbuf_get_pixels and
  # gdk_draw_rgb_image_dithalign, with pointer math to find the
  # correct index in the image data; that doesn't work well with
  # perl scalars, and besides, the GdkPixbuf method render_to_drawable
  # exists for this very purpose.
  $frame->render_to_drawable ($widget->window, $widget->style->black_gc,
                              $event->area->x, $event->area->y,
                              $event->area->x, $event->area->y,
                              $event->area->width, $event->area->height,
			      'normal',
                              $event->area->x, $event->area->y);

  return TRUE;
}

use constant CYCLE_LEN => 60;
use constant G_PI => 3.141529;
use POSIX;
sub MAX { $_[0] > $_[1] ? $_[0] : $_[1] }
sub MIN { $_[0] < $_[1] ? $_[0] : $_[1] }

my $frame_num = 0;

# Timeout handler to regenerate the frame
sub timeout {
  $background->copy_area (0, 0, $back_width, $back_height, $frame, 0, 0);

  my $f = ($frame_num % CYCLE_LEN) / CYCLE_LEN;

  my $xmid = $back_width / 2.0;
  my $ymid = $back_height / 2.0;

  my $radius = MIN ($xmid, $ymid) / 2.0;

  for (my $i = 0; $i < @images; $i++) {
      my $ang = 2.0 * G_PI * $i / @images - $f * 2.0 * G_PI;

      my $iw = $images[$i]->get_width;
      my $ih = $images[$i]->get_height;

      my $r = $radius + ($radius / 3.0) * sin ($f * 2.0 * G_PI);

      my $xpos = POSIX::floor ($xmid + $r * cos ($ang) - $iw / 2.0 + 0.5);
      my $ypos = POSIX::floor ($ymid + $r * sin ($ang) - $ih / 2.0 + 0.5);

      my $k = ($i & 1) ? sin ($f * 2.0 * G_PI) : cos ($f * 2.0 * G_PI);
      $k = 2.0 * $k * $k;
      $k = MAX (0.25, $k);

      my $r1 = Gtk2::Gdk::Rectangle->new ($xpos, $ypos, $iw * $k, $ih * $k);

      my $r2 = Gtk2::Gdk::Rectangle->new (0, 0, $back_width, $back_height);

      my $dest = $r1->intersect ($r2);
      if ($dest) {
	$images[$i]->composite ($frame,
			        $dest->x, $dest->y,
			        $dest->width, $dest->height,
			        $xpos, $ypos,
			        $k, $k,
			        'nearest',
			      (($i & 1)
			       ? MAX (127, abs (255 * sin ($f * 2.0 * G_PI)))
			       : MAX (127, abs (255 * cos ($f * 2.0 * G_PI)))));
      }
  }

  $da->queue_draw;

  $frame_num++;
  return TRUE;
}

my $timeout_id;

sub cleanup_callback {
  Glib::Source->remove ($timeout_id);
  $timeout_id = 0;
}

sub do {
  if (!$window) {
      $window = Gtk2::Window->new;
      $window->set_title ("Pixbufs");
      $window->set_resizable (FALSE);

      $window->signal_connect (destroy => sub {$window=undef; 1});
      $window->signal_connect (destroy => \&cleanup_callback);


      eval { load_pixbufs; };
      if ($@) {
	  my $dialog = Gtk2::MessageDialog->new ($window,
					   'destroy-with-parent',
					   'error',
					   'close',
					   "Failed to load an image: $@");

	  $dialog->signal_connect (response => sub { $_[0]->destroy; 1 });

	  $dialog->show;
      } else {
	  $window->set_size_request ($back_width, $back_height);

	  $frame = Gtk2::Gdk::Pixbuf->new ('rgb', FALSE, 8, $back_width, $back_height);

	  $da = Gtk2::DrawingArea->new;

	  $da->signal_connect (expose_event => \&expose_cb);

	  $window->add ($da);

	  $timeout_id = Glib::Timeout->add (FRAME_DELAY, \&timeout);
    }
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

#!/usr/bin/perl -w

# Rotated Text
#
# This demo shows how to use GDK and Pango to draw rotated and transformed
# text. The use of GdkPangoRenderer in this example is a somewhat advanced
# technique; most applications can simply use gdk_draw_layout(). We use
# it here mostly because that allows us to work in user coordinates - that is,
# coordinates prior to the application of the transformation matrix, rather
# than device coordinates.
#
# As of GTK+-2.6, the ability to draw transformed and anti-aliased graphics
# as shown in this example is only present for text. With GTK+-2.8, a new
# graphics system called "Cairo" will be introduced that provides these
# capabilities and many more for all types of graphics.
#

package rotated_text;

use strict;
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::Pango; # constants

my $window = undef;

sub min { $_[0] < $_[1] ? $_[0] : $_[1] }

sub rotated_text_expose_event {
  my ($widget, $event) = @_;

  use constant RADIUS => 150;
  use constant N_WORDS => 10;
  use constant FONT => "Sans Bold 27";
  use constant M_PI => 3.141526;

  my $matrix = Gtk2::Pango::Matrix->new; # all defaults

  my $width = $widget->allocation->width;
  my $height = $widget->allocation->height;

  # Get the default renderer for the screen, and set it up for drawing
  my $renderer = Gtk2::Gdk::PangoRenderer->get_default ($widget->get_screen);
  $renderer->set_drawable ($widget->window);
  $renderer->set_gc ($widget->style->black_gc);

  # Set up a transformation matrix so that the user space coordinates for
  # the centered square where we draw are [-RADIUS, RADIUS], [-RADIUS, RADIUS]
  # We first center, then change the scale
  my $device_radius = min ($width, $height) / 2.;
  $matrix->translate ($device_radius + ($width - 2 * $device_radius) / 2,
		      $device_radius + ($height - 2 * $device_radius) / 2);
  $matrix->scale ($device_radius / RADIUS, $device_radius / RADIUS);

  # Create a PangoLayout, set the font and text
  my $context = $widget->create_pango_context;
  my $layout = Gtk2::Pango::Layout->new ($context);
  $layout->set_text ("Text");
  my $desc = Gtk2::Pango::FontDescription->from_string (FONT);
  $layout->set_font_description ($desc);

  # Draw the layout N_WORDS times in a circle
  foreach my $i (0..N_WORDS-1) {
      my $rotated_matrix = $matrix->copy;
      my $angle = (360. * $i) / N_WORDS;

      # Gradient from red at angle == 60 to blue at angle == 300
      my $red   = 65535 * (1 + cos (($angle - 60) * M_PI / 180.)) / 2;
      my $green = 0;
      my $blue  = 65535  - $red;
      my $color = Gtk2::Gdk::Color->new ($red, $green, $blue);

      $renderer->set_override_color ('foreground', $color);

      $rotated_matrix->rotate ($angle);

      $context->set_matrix ($rotated_matrix);

      # Inform Pango to re-layout the text with the new transformation matrix
      $layout->context_changed;

      my ($width, $height) = $layout->get_size;
      $renderer->draw_layout ($layout, - $width / 2, - RADIUS * PANGO_SCALE);
  }

  # Clean up default renderer, since it is shared
  $renderer->set_override_color ('foreground', undef);
  $renderer->set_drawable (undef);
  $renderer->set_gc (undef);

  return FALSE;
}

sub do {
  my $do_widget = shift;

  if (!$window) {
      my $white = Gtk2::Gdk::Color->new (0xffff, 0xffff, 0xffff);

      $window = Gtk2::Window->new;
      $window->set_screen ($do_widget->get_screen);
      $window->set_title ("Rotated Text");

      $window->signal_connect (destroy => sub { $window = undef; });

      my $drawing_area = Gtk2::DrawingArea->new;
      $window->add ($drawing_area);

      # This overrides the background color from the theme
      $drawing_area->modify_bg ('normal', $white);

      $drawing_area->signal_connect
	      	(expose_event => \&rotated_text_expose_event);

      $window->set_default_size (2 * RADIUS, 2 * RADIUS);

  }

  if (! $window->visible) {
      $window->show_all;
  } else {
      $window->destroy;
      $window = undef;
  }

  return $window;
}

1;

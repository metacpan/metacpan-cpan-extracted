#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 15;

# $Id$

my $window = Gtk2::Window -> new();

#
# Force the window all the way to the screen, so that the realization and
# mapping process completes before we continue.  Otherwise, we have issues
# with X interactions on some servers.
#
$window -> show_now();

my $win = $window -> window();

SKIP: {
  skip("GdkDisplay and GdkScreen are new in 2.2", 2)
    unless Gtk2->CHECK_VERSION (2, 2, 0);

  isa_ok($win -> get_display(), "Gtk2::Gdk::Display");
  isa_ok($win -> get_screen(), "Gtk2::Gdk::Screen");
}

isa_ok($win -> get_visual(), "Gtk2::Gdk::Visual");

my $colormap = Gtk2::Gdk::Colormap -> get_system();

$win -> set_colormap($colormap);
is($win -> get_colormap(), $colormap);

like($win -> get_depth(), qr/^\d+$/);

my ($w, $h) = $win -> get_size();
like($w, qr/^\d+$/);
like($h, qr/^\d+$/);

isa_ok($win -> get_clip_region(), "Gtk2::Gdk::Region");
isa_ok($win -> get_visible_region(), "Gtk2::Gdk::Region");

my $black = Gtk2::Gdk::Color -> new(0, 0, 0);

my $values = {
  foreground => $black,
  background => $black,
  function => "copy",
  fill => "tiled",
  subwindow_mode => "clip-by-children",
  ts_x_origin => 0,
  ts_y_origin => 0,
  clip_x_origin => 0,
  clip_y_origin => 0,
  graphics_exposures => 1,
  line_width => 5,
  line_style => "solid",
  cap_style => "butt",
  join_style => "round"
};

my $gc = Gtk2::Gdk::GC -> new_with_values($window -> window(), $values);
my $layout = $window -> create_pango_layout("Bla!");

$win -> draw_point($gc, 10, 10);
$win -> draw_points($gc);  # no points
$win -> draw_points($gc, 10, 10, 11, 11, 12, 12, 13, 13);
$win -> draw_line($gc, 5, 5, 10, 10);
$win -> draw_lines($gc);  # no lines
$win -> draw_lines($gc, 5, 5, 10, 10, 15, 15, 20, 20);
$win -> draw_segments($gc);
$win -> draw_segments($gc, 1, 2, 3, 4, 10, 11, 12, 13);
$win -> draw_rectangle($gc, 1, 0, 0, 10, 10);
$win -> draw_arc($gc, 1, 5, 5, 10, 10, 23, 42);
$win -> draw_polygon($gc, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6);
$win -> draw_layout_line($gc, 10, 10, $layout -> get_line(0));
$win -> draw_layout($gc, 10, 10, $layout);
$win -> draw_layout_line_with_colors($gc, 10, 10, $layout -> get_line(0), $black, $black);
$win -> draw_layout_line_with_colors($gc, 10, 10, $layout -> get_line(0), $black, undef);
$win -> draw_layout_with_colors($gc, 10, 10, $layout, $black, $black);
$win -> draw_layout_with_colors($gc, 10, 10, $layout, undef,  $black);
$win -> draw_drawable($gc, $win, 5, 5, 5, 5, 10, 10);

SKIP: {
  my $image = $win -> get_image(5, 5, 10, 10);
  skip("get_image returned undef, skipping draw_image", 2)
    unless (defined($image));

  isa_ok($image, "Gtk2::Gdk::Image");
  $win -> draw_image($gc, $image, 0, 0, 0, 0, 50, 50);

  require Scalar::Util;
  Scalar::Util::weaken ($image);
  is ($image, undef, 'get_image() resulting image destroyed when unreferenced');
}

SKIP: {
  skip("draw_pixbuf is new in 2.2", 0)
    unless Gtk2->CHECK_VERSION (2, 2, 0);

  $win -> draw_pixbuf($gc, Gtk2::Gdk::Pixbuf -> new("rgb", 0, 8, 10, 10), 0, 0, 0, 0, -1, -1, "none", 5, 5);

  #test with no gc
  $win -> draw_pixbuf(undef, Gtk2::Gdk::Pixbuf -> new("rgb", 0, 8, 10, 10), 0, 0, 0, 0, -1, -1, "none", 5, 5);
}

SKIP: {
  skip("copy_to_image is new in 2.4", 2)
    unless Gtk2->CHECK_VERSION (2, 4, 0);

  my $image = $win -> copy_to_image(undef, 0, 0, 0, 0, 50, 50);
  skip ("copy_to_image returned undef", 2)
    unless (defined($image));

  isa_ok($image, "Gtk2::Gdk::Image",
	'copy_to_image() creating an image');

  require Scalar::Util;
  Scalar::Util::weaken ($image);
  is ($image, undef,
      'copy_to_image() creating an image - destroyed when unreferenced');
}

SKIP: {
  skip("copy_to_image is new in 2.4", 1)
    unless Gtk2->CHECK_VERSION (2, 4, 0);
  my $existing_image = $win -> get_image(5, 5, 10, 10);
  skip("get_image returned undef, skipping draw_image", 2)
    unless (defined($existing_image));

  my $image = $win -> copy_to_image($existing_image, 0, 0, 0, 0, 50, 50);

  skip ("copy_to_image returned undef", 1)
    unless (defined($image));

  isa_ok($image, "Gtk2::Gdk::Image",
	 'copy_to_image() to a given target image');

  require Scalar::Util;
  Scalar::Util::weaken ($image);
  Scalar::Util::weaken ($existing_image);
  is ($image, undef,
      'copy_to_image() to a given target image - destroyed when unreferenced');
}

__END__

Copyright (C) 2003-2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 35;

# $Id$

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

my $window = Gtk2::Window -> new();
$window -> realize();

my $gc = Gtk2::Gdk::GC -> new($window -> window());
isa_ok($gc, "Gtk2::Gdk::GC");

$gc -> copy($gc);

$gc -> set_values($values);
check_values();

$gc = Gtk2::Gdk::GC -> new($window -> window(), $values);
isa_ok($gc, "Gtk2::Gdk::GC");

$gc = Gtk2::Gdk::GC -> new_with_values($window -> window(), $values);
isa_ok($gc, "Gtk2::Gdk::GC");

SKIP: {
  skip "GdkScreen is new in 2.2", 1
    unless Gtk2->CHECK_VERSION (2,2,0);
  isa_ok($gc -> get_screen(), "Gtk2::Gdk::Screen");
}

my $pixmap = Gtk2::Gdk::Pixmap -> new($window -> window(), 10, 10, 8);
my $rectangle = Gtk2::Gdk::Rectangle -> new(23, 42, 10, 10);
my $region = Gtk2::Gdk::Region -> rectangle($rectangle);
my $colormap = Gtk2::Gdk::Colormap -> get_system();
my $bitmap = Gtk2::Gdk::Bitmap -> create_from_data($window -> window(), "", 1, 1);

$gc -> set_foreground($black);
$gc -> set_background($black);
$gc -> set_rgb_fg_color($black);
$gc -> set_rgb_bg_color($black);
$gc -> set_function("copy");
$gc -> set_fill("tiled");
$gc -> set_tile($pixmap);
$gc -> set_stipple($pixmap);
$gc -> set_ts_origin(0, 0);
$gc -> set_clip_origin(0, 0);
$gc -> set_clip_mask(undef);
$gc -> set_clip_mask($bitmap);
$gc -> set_clip_rectangle(undef);
$gc -> set_clip_rectangle($rectangle);
$gc -> set_clip_region(undef);
$gc -> set_clip_region($region);
$gc -> set_subwindow("clip-by-children");
$gc -> set_exposures(1);
$gc -> set_line_attributes(5, "solid", "butt", "round");
$gc -> set_dashes(0, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
$gc -> offset(0, 0);

$gc -> set_colormap($colormap);
is($gc -> get_colormap(), $colormap);

check_values();

sub check_values {
  my $new_values = $gc -> get_values();
  isa_ok($new_values, "HASH");
  isa_ok($new_values -> { foreground }, "Gtk2::Gdk::Color");
  isa_ok($new_values -> { background }, "Gtk2::Gdk::Color");
  is($new_values -> { function }, "copy");
  is($new_values -> { fill }, "tiled");
  is($new_values -> { subwindow_mode }, "clip-by-children");
  is($new_values -> { ts_x_origin }, 0);
  is($new_values -> { ts_y_origin }, 0);
  is($new_values -> { clip_x_origin }, 0);
  is($new_values -> { clip_y_origin }, 0);
  is($new_values -> { graphics_exposures }, 1);
  is($new_values -> { line_width }, 5);
  is($new_values -> { line_style }, "solid");
  is($new_values -> { cap_style }, "butt");
  is($new_values -> { join_style }, "round");
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

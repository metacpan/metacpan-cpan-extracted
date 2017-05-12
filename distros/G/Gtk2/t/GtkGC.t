#!/usr/bin/perl -w
# vim: set filetype=perl :
use strict;
use Gtk2::TestHelper tests => 3;

use Scalar::Util;

# $Id$

my $black = Gtk2::Gdk::Color -> new(0, 0, 0);
my $colormap = Gtk2::Gdk::Colormap -> get_system();

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

my $gc = Gtk2::GC -> get(16, $colormap, $values);
isa_ok($gc, "Gtk2::Gdk::GC");
isa_ok($gc, "Gtk2::GC");

Gtk2::GC -> release($gc);

# regression tests for the automatic releasing of GCs
my ($save, $weak_ref);
{
  my $one = Gtk2::GC -> get(16, $colormap, $values);
  Gtk2::GC -> get(16, $colormap, $values);
  Gtk2::GC -> get(16, $colormap, $values);
  Gtk2::GC -> release($one);
  Gtk2::GC -> release($one);
  Gtk2::GC -> release($one);
  $one = undef;

  my $two = Gtk2::GC -> get(32, $colormap, $values);
  Gtk2::GC -> get(32, $colormap, $values);
  { my $three = Gtk2::GC -> get(32, $colormap, $values); }
  $save = Gtk2::GC -> get(32, $colormap, $values);
  Gtk2::GC -> get(32, $colormap, $values);

  Scalar::Util::weaken ($weak_ref = $two);
}
$save = undef;
is ($weak_ref, undef);

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

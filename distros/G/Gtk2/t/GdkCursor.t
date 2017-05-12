#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 9;

# $Id$

my $cursor = Gtk2::Gdk::Cursor -> new("watch");
isa_ok($cursor, "Gtk2::Gdk::Cursor");
is($cursor -> type(), "watch");

# new_from_pixmap

use constant width => 16;
use constant height => 16;
my $eyes_bits = pack 'C*',
   0x18, 0x18, 0x24, 0x24, 0x42, 0x42, 0x42, 0x42, 0xe1, 0xe1, 0xf1, 0xf1,
   0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xe1, 0xe1,
   0x42, 0x42, 0x42, 0x42, 0x24, 0x24, 0x18, 0x18;

my $eyes_mask_bits = pack 'C*',
   0x18, 0x18, 0x3c, 0x3c, 0x7e, 0x7e, 0x7e, 0x7e, 0xff, 0xff, 0xff, 0xff,
   0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
   0x7e, 0x7e, 0x7e, 0x7e, 0x3c, 0x3c, 0x18, 0x18;

my $fg = Gtk2::Gdk::Color->new (0, 0, 0); # black
my $bg = Gtk2::Gdk::Color->new (65535, 65535, 65535); # white
my $source = Gtk2::Gdk::Bitmap->create_from_data (undef, $eyes_bits, width, height);
my $mask = Gtk2::Gdk::Bitmap->create_from_data (undef, $eyes_mask_bits, width, height);
$cursor = Gtk2::Gdk::Cursor->new_from_pixmap ($source, $mask, $fg, $bg, 8, 8);
isa_ok($cursor, "Gtk2::Gdk::Cursor");

SKIP: {
  skip("new_for_display is new in 2.2", 2)
    unless Gtk2 -> CHECK_VERSION(2, 2, 0);

  my $display = Gtk2::Gdk::Display -> get_default();

  $cursor = Gtk2::Gdk::Cursor -> new_for_display($display, "watch");
  isa_ok($cursor, "Gtk2::Gdk::Cursor");
  is($cursor -> get_display(), $display);
}

SKIP: {
  skip("new_from_pixbuf is new in 2.4", 1)
    unless Gtk2 -> CHECK_VERSION(2, 4, 0);

  my $display = Gtk2::Gdk::Display -> get_default();
  my $pixbuf = Gtk2::Gdk::Pixbuf -> new("rgb", 0, 8, 10, 10);
  my $cursor = Gtk2::Gdk::Cursor -> new_from_pixbuf($display, $pixbuf, 5, 5);
  isa_ok($cursor, "Gtk2::Gdk::Cursor");
}

SKIP: {
  skip("new 2.8 stuff", 2)
    unless Gtk2->CHECK_VERSION (2, 8, 0);

  my $display = Gtk2::Gdk::Display -> get_default();

  # new_from_name will return undef if there is no cursor with that name.
  # this can happen with different cursor themes and such.
  my $cursor = Gtk2::Gdk::Cursor -> new_from_name($display, "watch");
  skip "no cursor named 'watch'; that probably means that new_from_name works.", 2
    unless $cursor;
  isa_ok($cursor, "Gtk2::Gdk::Cursor");

  my $pixbuf = $cursor -> get_image();
  ok(!defined $pixbuf || UNIVERSAL::isa($pixbuf, "Gtk2::Gdk::Pixbuf"));
}

SKIP: {
  skip 'new 2.22 stuff', 1
    unless Gtk2->CHECK_VERSION(2, 22, 0);

  my $display = Gtk2::Gdk::Display -> get_default();
  my $pixbuf = Gtk2::Gdk::Pixbuf -> new("rgb", 0, 8, 10, 10);
  my $cursor = Gtk2::Gdk::Cursor -> new_from_pixbuf($display, $pixbuf, 5, 5);
  ok(defined $cursor -> get_cursor_type());
}

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

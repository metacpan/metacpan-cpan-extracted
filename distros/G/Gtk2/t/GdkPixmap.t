#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 6;

# $Id$

my $window = Gtk2::Window -> new();
$window -> realize();

SKIP: {
  skip("I need X11 for this", 6)
    unless ($window -> window() -> can("get_xid"));

  my $xid = $window -> window() -> get_xid();

  isa_ok(Gtk2::Gdk::Pixmap -> foreign_new($xid), "Gtk2::Gdk::Pixmap");
  isa_ok(Gtk2::Gdk::Pixmap -> lookup($xid), "Gtk2::Gdk::Pixmap");

  SKIP: {
    skip("GdkDisplay is new in 2.2", 3)
      unless Gtk2 -> CHECK_VERSION(2, 2, 0);

    my $display = Gtk2::Gdk::Display -> get_default();

    isa_ok(Gtk2::Gdk::Pixmap -> foreign_new_for_display($display, $xid), "Gtk2::Gdk::Pixmap");
    isa_ok(Gtk2::Gdk::Pixmap -> lookup_for_display($display, $xid), "Gtk2::Gdk::Pixmap");

    ok (! Gtk2::Gdk::Pixmap->create_from_xpm ($window->window, undef,
					      'non-existent.xpm'),
	'asking for non-existent xpm returns undef');

    # XXX missing tests for the rest of the GdkPixmap API.
  }

  SKIP: {
    skip("2.10 stuff", 1)
      unless Gtk2 -> CHECK_VERSION(2, 10, 0);

    my $screen = Gtk2::Gdk::Screen -> get_default();
    my $pixmap =
      Gtk2::Gdk::Pixmap -> foreign_new_for_screen($screen, $xid, 23, 42, 16);
    isa_ok($pixmap, "Gtk2::Gdk::Pixmap");
  }
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

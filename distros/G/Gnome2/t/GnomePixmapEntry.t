#!/usr/bin/perl -w
use strict;
use Gnome2;

use constant TESTS => 3;
use Test::More tests => TESTS;

# $Id$

###############################################################################

SKIP: {
  our $application;
  do "t/TestBoilerplate";

  #############################################################################

  my $entry = Gnome2::PixmapEntry -> new("schmih", "Schmah", 1);
  isa_ok($entry, "Gnome2::PixmapEntry");
  isa_ok($entry -> scrolled_window(), "Gtk2::ScrolledWindow");
  isa_ok($entry -> preview_widget(), "Gtk2::Widget");

  $entry -> set_pixmap_subdir("nautilus");
  $entry -> set_preview(1);
  $entry -> set_preview_size(23, 42);

  $entry -> get_filename();
}

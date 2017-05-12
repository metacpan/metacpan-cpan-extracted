#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 20;

# $Id$

foreach (Gtk2::Gdk -> SELECTION_PRIMARY(),
         Gtk2::Gdk -> SELECTION_SECONDARY(),
         Gtk2::Gdk -> SELECTION_CLIPBOARD(),
         Gtk2::Gdk -> TARGET_BITMAP(),
         Gtk2::Gdk -> TARGET_COLORMAP(),
         Gtk2::Gdk -> TARGET_DRAWABLE(),
         Gtk2::Gdk -> TARGET_PIXMAP(),
         Gtk2::Gdk -> TARGET_STRING(),
         Gtk2::Gdk -> SELECTION_TYPE_ATOM(),
         Gtk2::Gdk -> SELECTION_TYPE_BITMAP(),
         Gtk2::Gdk -> SELECTION_TYPE_COLORMAP(),
         Gtk2::Gdk -> SELECTION_TYPE_DRAWABLE(),
         Gtk2::Gdk -> SELECTION_TYPE_INTEGER(),
         Gtk2::Gdk -> SELECTION_TYPE_PIXMAP(),
         Gtk2::Gdk -> SELECTION_TYPE_WINDOW(),
         Gtk2::Gdk -> SELECTION_TYPE_STRING()) {
  isa_ok($_, "Gtk2::Gdk::Atom");
}

my $primary = Gtk2::Gdk -> SELECTION_PRIMARY();
my $target = Gtk2::Gdk -> TARGET_STRING();
my $property = Gtk2::Gdk -> SELECTION_TYPE_STRING();

my $window = Gtk2::Window -> new();
$window -> realize();

is(Gtk2::Gdk::Selection -> owner_set($window -> window(), $primary, 0, 0), 1);
my $owner = Gtk2::Gdk::Selection -> owner_get($primary);
SKIP: {
  skip 'owner_get returned undef', 1 unless defined $owner;
  is($owner, $window -> window())
};

Gtk2::Gdk::Selection -> convert($window -> window(), $primary, $target, 0);

SKIP: {
  skip("GdkDisplay is new in 2.2", 2)
    unless Gtk2->CHECK_VERSION (2, 2, 0);

  my $display = Gtk2::Gdk::Display -> get_default();

  is(Gtk2::Gdk::Selection -> owner_set_for_display($display, $window -> window(), $primary, 0, 0), 1);
  is(Gtk2::Gdk::Selection -> owner_get_for_display($display, $primary), $window -> window());

  if ($window -> window() -> can("get_xid")) {
    Gtk2::Gdk::Selection -> send_notify_for_display(
      $display, $window -> window() -> get_xid(),
      $primary, $target, $property, 0);
  }
}

if ($window -> window() -> can("get_xid")) {
  Gtk2::Gdk::Selection -> send_notify(
    $window -> window() -> get_xid(),
    $primary, $target, $property, 0);
}

# FIXME: warn Gtk2::Gdk::Selection -> property_get($window -> window());

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

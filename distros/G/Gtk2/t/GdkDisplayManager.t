#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  tests => 4,
  at_least_version => [2, 2, 0, "GdkDisplayManager is new in 2.2"];

# $Id$

my $manager = Gtk2::Gdk::DisplayManager -> get();
isa_ok($manager, "Gtk2::Gdk::DisplayManager");

my $display = Gtk2::Gdk::Display -> get_default();

$manager -> set_default_display($display);
is($manager -> get_default_display(), $display);

is(($manager -> list_displays())[0], $display);

isa_ok($display -> get_core_pointer(), "Gtk2::Gdk::Device");

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 3, noinit => 1;

# $Id$

my $box = Gtk2::EventBox -> new();
isa_ok($box, "Gtk2::EventBox");

SKIP: {
  skip("[sg]et_above_child and [sg]et_visible_window are new in 2.4", 2)
    unless Gtk2->CHECK_VERSION (2, 4, 0);

  $box -> set_above_child(1);
  is($box -> get_above_child(), 1);

  $box -> set_visible_window(1);
  is($box -> get_visible_window(), 1);
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

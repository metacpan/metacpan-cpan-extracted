#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 7;

# $Id$

my $item = Gtk2::CheckMenuItem -> new();
isa_ok($item, "Gtk2::CheckMenuItem");

$item = Gtk2::CheckMenuItem -> new("_Bla");
isa_ok($item, "Gtk2::CheckMenuItem");

$item = Gtk2::CheckMenuItem -> new_with_label("Bla");
isa_ok($item, "Gtk2::CheckMenuItem");

$item = Gtk2::CheckMenuItem -> new_with_mnemonic("Bla");
isa_ok($item, "Gtk2::CheckMenuItem");

$item -> set_active(1);
is($item -> get_active(), 1);

$item -> toggled();

$item -> set_inconsistent(1);
is($item -> get_inconsistent(), 1);

SKIP: {
  skip("[sg]et_draw_as_radio are new in 2.4", 1)
    unless Gtk2->CHECK_VERSION (2, 4, 0);

  $item -> set_draw_as_radio(1);
  is($item -> get_draw_as_radio(), 1);
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 9;

# $Id$

my $button = Gtk2::ToggleButton -> new();
isa_ok($button, "Gtk2::ToggleButton");
is($button -> get("label"), undef);

$button = Gtk2::ToggleButton -> new_with_label("Bla");
isa_ok($button, "Gtk2::ToggleButton");
is($button -> get("label"), "Bla");

$button = Gtk2::ToggleButton -> new_with_mnemonic("_Bla");
isa_ok($button, "Gtk2::ToggleButton");
is($button -> get("label"), "_Bla");

$button -> set_mode(1);
is($button -> get_mode(), 1);

$button -> set_active(1);
is($button -> get_active(), 1);

$button -> set_inconsistent(1);
is($button -> get_inconsistent(), 1);

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

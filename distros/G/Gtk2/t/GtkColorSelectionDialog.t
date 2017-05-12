#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 6;

# $Id$

my $dialog = Gtk2::ColorSelectionDialog -> new("Bla");
isa_ok($dialog, "Gtk2::ColorSelectionDialog");
isa_ok($dialog -> get_color_selection(), "Gtk2::ColorSelection");
isa_ok($dialog -> ok_button(), "Gtk2::Button");
isa_ok($dialog -> cancel_button(), "Gtk2::Button");
isa_ok($dialog -> help_button(), "Gtk2::Button");

# Deprecated.
ok($dialog -> colorsel() == $dialog -> get_color_selection());

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

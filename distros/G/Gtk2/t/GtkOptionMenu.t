#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 3;

# $Id$

my $option_menu = Gtk2::OptionMenu -> new();
isa_ok($option_menu, "Gtk2::OptionMenu");

my $menu = Gtk2::Menu -> new();
$menu -> append(Gtk2::MenuItem -> new_with_label("Bla"));
$menu -> append(Gtk2::MenuItem -> new_with_label("Blub"));

$option_menu -> set_menu($menu);
is($option_menu -> get_menu(), $menu);

$option_menu -> set_history(1);
is($option_menu -> get_history(), 1);

$option_menu -> remove_menu();

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

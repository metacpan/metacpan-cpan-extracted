#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 5;

# $Id$

Gtk2 -> init();

###############################################################################

my $default = Gnome2::Dia::DefaultTool -> new();
isa_ok($default, "Gnome2::Dia::DefaultTool");
isa_ok($default, "Gnome2::Dia::Tool");

$default -> set_handle_tool($default);
is($default -> get_handle_tool(), $default);

$default -> set_item_tool($default);
is($default -> get_item_tool(), $default);

$default -> set_selection_tool($default);
is($default -> get_selection_tool(), $default);

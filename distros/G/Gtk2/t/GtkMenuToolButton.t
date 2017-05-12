#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  tests => 5,
  at_least_version => [2, 6, 0, "GtkMenuToolButton is new in 2.6"];

# $Id$

my $label = Gtk2::Label -> new("Urgs");

my $button = Gtk2::MenuToolButton -> new($label, "Urgs");
isa_ok($button, "Gtk2::MenuToolButton");

$button = Gtk2::MenuToolButton -> new(undef, undef);
isa_ok($button, "Gtk2::MenuToolButton");

$button = Gtk2::MenuToolButton -> new_from_stock("gtk-ok");
isa_ok($button, "Gtk2::MenuToolButton");

my $menu = Gtk2::Menu -> new();

$button -> set_menu($menu);
is($button -> get_menu(), $menu);

$button -> set_menu(undef);
is($button -> get_menu(), undef);

my $tooltips = Gtk2::Tooltips -> new();

$button -> set_arrow_tooltip($tooltips, "Urgs", "Urgs");

SKIP: {
  skip 'new 2.12 stuff', 0
    unless Gtk2 -> CHECK_VERSION(2, 12, 0);

  $button -> set_arrow_tooltip_text('Bla!');
  $button -> set_arrow_tooltip_text(undef);
  $button -> set_arrow_tooltip_markup('<b>Bla!</b>');
  $button -> set_arrow_tooltip_markup(undef);
}

__END__

Copyright (C) 2004 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

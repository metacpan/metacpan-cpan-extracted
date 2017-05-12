#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 3;

# $Id$

my $shell = Gtk2::Menu -> new();
isa_ok($shell, "Gtk2::MenuShell");

my $item_one = Gtk2::MenuItem -> new();
my $item_two = Gtk2::MenuItem -> new();
my $item_three = Gtk2::MenuItem -> new();

$item_one -> signal_connect(activate => sub {
  is(shift(), $item_one);
});

$shell -> append($item_one);
$shell -> prepend($item_two);
$shell -> insert($item_three, 1);

$shell -> deactivate();
$shell -> select_item($item_three);
$shell -> deselect();
$shell -> activate_item($item_one, 1);

SKIP: {
  skip("select_first is new in 2.2", 0)
    unless Gtk2->CHECK_VERSION (2, 2, 0);

  $shell -> select_first(0);
}

SKIP: {
  skip("cancel is new in 2.4", 0)
    unless Gtk2->CHECK_VERSION (2, 4, 0);

  $shell -> cancel();
}

SKIP: {
  skip("new 2.8 stuff", 1)
    unless Gtk2->CHECK_VERSION (2, 8, 0);

  $shell -> set_take_focus(TRUE);
  ok($shell -> get_take_focus());
}

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

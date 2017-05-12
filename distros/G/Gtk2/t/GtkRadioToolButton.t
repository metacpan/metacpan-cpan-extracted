#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  at_least_version => [2, 4, 0, "Action-based menus are new in 2.4"],
  tests => 12;

# $Id$

my $item = Gtk2::RadioToolButton -> new();
isa_ok($item, "Gtk2::RadioToolButton");

my $item_two = Gtk2::RadioToolButton -> new(undef);
isa_ok($item_two, "Gtk2::RadioToolButton");

my $item_three = Gtk2::RadioToolButton -> new([$item, $item_two]);
isa_ok($item_three, "Gtk2::RadioToolButton");

$item_two = Gtk2::RadioToolButton -> new_from_stock(undef, "gtk-quit");
isa_ok($item_two, "Gtk2::RadioToolButton");

$item_three = Gtk2::RadioToolButton -> new_from_stock([$item, $item_two], "gtk-quit");
isa_ok($item_three, "Gtk2::RadioToolButton");

$item = Gtk2::RadioToolButton -> new_from_widget($item_two);
isa_ok($item, "Gtk2::RadioToolButton");

$item = Gtk2::RadioToolButton -> new_with_stock_from_widget($item_two, "gtk-quit");
isa_ok($item, "Gtk2::RadioToolButton");

$item = Gtk2::RadioToolButton -> new();

$item -> set_group([$item_two, $item_three]);
is_deeply($item -> get_group(), [$item_two, $item_three]);
{
  # get_group() no memory leaks in arrayref return and array items
  my $x = Gtk2::RadioToolButton->new;
  my $y = Gtk2::RadioToolButton->new;
  $y->set_group($x);
  my $aref = $x->get_group;
  is_deeply($aref, [$x,$y]);
  require Scalar::Util;
  Scalar::Util::weaken ($aref);
  is ($aref, undef, 'get_group() array destroyed by weakening');
  Scalar::Util::weaken ($x);
  is ($x, undef, 'get_group() item x destroyed by weakening');
  Scalar::Util::weaken ($y);
  is ($y, undef, 'get_group() item y destroyed by weakening');
}

__END__

Copyright (C) 2003, 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

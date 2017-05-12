#!/usr/bin/perl -w
# vim: set ft=perl  et sw=2 sts=2 :
use strict;
use Gtk2::TestHelper tests => 5, noinit => 1;

# $Id$

my $group = Gtk2::SizeGroup -> new("vertical");
isa_ok($group, "Gtk2::SizeGroup");

$group -> set_mode("horizontal");
is($group -> get_mode(), "horizontal");

my $label = Gtk2::Label -> new("Bla");

$group -> add_widget($label);
$group -> remove_widget($label);

SKIP: {
  skip("new 2.8 stuff", 1)
    unless Gtk2->CHECK_VERSION (2, 8, 0);

  $group -> set_ignore_hidden(TRUE);
  ok($group -> get_ignore_hidden());
}

SKIP: {
  skip("new 2.10 stuff", 2)
    unless Gtk2->CHECK_VERSION (2, 10, 0);

  # we last left it empty.
  my @widgets = $group->get_widgets;
  ok(!@widgets);

  my ($uno, $dos, $tres, $cuatro) =
    (Gtk2::Label->new ("Tinky-Winky"),
     Gtk2::Label->new ("Dipsy"),
     Gtk2::Label->new ("La La"),
     Gtk2::Label->new ("Po"));

  # now add a few and try again.
  $group->add_widget($uno);
  $group->add_widget($dos);
  $group->add_widget($tres);
  $group->add_widget($cuatro);
  @widgets = $group->get_widgets;
  is (scalar @widgets, 4);
  # i don't think we can count on an order.  do we care about ensuring
  # that the same widgets are in the group as we added?
}

__END__

Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

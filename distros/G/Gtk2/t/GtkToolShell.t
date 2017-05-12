#!/usr/bin/perl
use strict;
use warnings;
use Gtk2::TestHelper
  tests => 9,
  at_least_version => [2, 14, 0, 'GtkToolShell is new in 2.14'],
  ;

# $Id$

my $toolbar = Gtk2::Toolbar->new ();
isa_ok ($toolbar, 'Gtk2::ToolShell');

ok (defined $toolbar->get_icon_size ());
ok (defined $toolbar->get_orientation ());
ok (defined $toolbar->get_relief_style ());
ok (defined $toolbar->get_style ());
$toolbar->rebuild_menu ();

SKIP: {
  skip 'new 2.20 stuff', 4
    unless Gtk2->CHECK_VERSION(2, 20, 0);

  ok (defined $toolbar->get_ellipsize_mode);
  ok (defined $toolbar->get_text_alignment);
  ok (defined $toolbar->get_text_orientation);

  my $palette = Gtk2::ToolPalette->new;
  my $bar = Gtk2::ToolItemGroup->new ('Test');
  $palette->add ($bar);
  isa_ok ($bar->get_text_size_group, 'Gtk2::SizeGroup');
}

__END__

Copyright (C) 2008 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

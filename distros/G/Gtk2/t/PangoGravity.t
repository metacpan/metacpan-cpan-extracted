#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 4, noinit => 1;

# $Id$

SKIP: {
  skip "PangoGravity", 4
    unless Gtk2::Pango->CHECK_VERSION (1, 16, 0);

  is (Gtk2::Pango::Gravity::to_rotation ('south'), 0.0);
  ok (!Gtk2::Pango::Gravity::is_vertical ('south'));

  my $matrix = Gtk2::Pango::Matrix->new;
  is (Gtk2::Pango::Gravity::get_for_matrix ($matrix), 'south');

  is (Gtk2::Pango::Gravity::get_for_script ('common', 'south', 'strong'), 'south');
}

__END__

Copyright (C) 2007 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

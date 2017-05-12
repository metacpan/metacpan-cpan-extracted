#!/usr/bin/perl -w
# vim: set ft=perl :

use strict;
use Gtk2::TestHelper
  tests => 3,
  noinit => 1,
  at_least_version => [2, 10, 0, "Gtk2::CellRendererSpin is new in 2.10"];

my $cell = Gtk2::CellRendererSpin->new;
isa_ok ($cell, 'Gtk2::CellRendererSpin');
isa_ok ($cell, 'Gtk2::CellRendererText');
isa_ok ($cell, 'Gtk2::CellRenderer');

__END__

Copyright (C) 2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

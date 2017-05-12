#!/usr/bin/perl -w
# vim: set ft=perl :

use strict;
use Gtk2::TestHelper
  tests => 3,
  noinit => 1,
  at_least_version => [2, 10, 0, "Gtk2::CellRendererAccel is new in 2.10"];

my $cell = Gtk2::CellRendererAccel->new;
isa_ok ($cell, 'Gtk2::CellRendererAccel');
isa_ok ($cell, 'Gtk2::CellRenderer');

$cell->set (accel_mode => 'other');
is ($cell->get ('accel_mode'), 'other');

__END__

Copyright (C) 2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

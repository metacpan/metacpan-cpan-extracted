#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  tests => 1, noinit => 1,
  at_least_version => [2, 6, 0, "GtkCellRendererProgress is new in 2.6"];

# $Id$

my $text = Gtk2::CellRendererProgress -> new();
isa_ok($text, "Gtk2::CellRendererProgress");

__END__

Copyright (C) 2004 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

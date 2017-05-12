#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 1, noinit => 1;

# $Id$

my $pixbuf = Gtk2::CellRendererPixbuf -> new();
isa_ok($pixbuf, "Gtk2::CellRendererPixbuf");

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

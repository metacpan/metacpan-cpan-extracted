#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 1, noinit => 1;

# $Id$

my $text = Gtk2::CellRendererText -> new();
isa_ok($text, "Gtk2::CellRendererText");

$text -> set_fixed_height_from_font(5);

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

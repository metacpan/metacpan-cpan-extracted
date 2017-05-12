#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 2, noinit => 1;

# $Id$

my $adjustment = Gtk2::Adjustment -> new(0, 0, 100, 1, 5, 10);

my $bar = Gtk2::HScrollbar -> new($adjustment);
isa_ok($bar, "Gtk2::Scrollbar");
isa_ok($bar, "Gtk2::HScrollbar");

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 1, noinit => 1;

# $Id$

my $item = Gtk2::SeparatorMenuItem -> new();
isa_ok($item, "Gtk2::SeparatorMenuItem");

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

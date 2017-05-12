#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 1, noinit => 1;

# $Id$

my $ruler = Gtk2::VRuler -> new();
isa_ok($ruler, "Gtk2::VRuler");

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 3, noinit => 1;

# $Id$

my $box = Gtk2::HButtonBox -> new();
isa_ok($box, "Gtk2::HButtonBox");

$box -> set_layout_default("spread");
is($box -> get_layout_default(), "spread");

$box -> set_spacing_default(23);
is($box -> get_spacing_default(), 23);

__END__

Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

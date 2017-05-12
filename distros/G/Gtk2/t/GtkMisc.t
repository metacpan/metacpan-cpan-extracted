#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 2, noinit => 1;

# $Id$

my $misc = Gtk2::Misc -> new(Gtk2::Label::);

$misc -> set_alignment(0.5, 0.5);
is_deeply([$misc -> get_alignment()], [0.5, 0.5]);

$misc -> set_padding(23, 42);
is_deeply([$misc -> get_padding()], [23, 42]);

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 1;

# $Id$

my $dialog = Gtk2::InputDialog -> new();
isa_ok($dialog, "Gtk2::InputDialog");

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 2, noinit => 1;

# $Id$

my $alignment = Gtk2::Alignment -> new(2.3, 4.2, 7, 13);
isa_ok($alignment, "Gtk2::Alignment");

$alignment -> set(2.3, 4.2, 7, 13);

SKIP: {
  skip("[sg]et_padding are new in 2.4", 1)
    unless Gtk2->CHECK_VERSION (2, 4, 0);

  $alignment -> set_padding(1, 2, 3, 4);
  is_deeply([$alignment -> get_padding()], [1, 2, 3, 4]);
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

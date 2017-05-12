#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 4, noinit => 1;

# $Id$

# Blatantly stolen from Ross' original test.

my $frame = Gtk2::AspectFrame -> new("Label", 1, 1, 3, 0);
isa_ok($frame, "Gtk2::AspectFrame");
is_deeply([$frame -> get(qw/xalign yalign ratio obey-child/)],
          [1, 1, 3, 0], '$aspect->new, verify');

$frame -> set_params(1, 1, 6, 1);
is_deeply([$frame -> get(qw/xalign yalign ratio obey-child/)],
          [1, 1, 6, 1], '$aspect->set_params, verify');

# label can be undef for no label
$frame = Gtk2::AspectFrame -> new(undef, 1, 1, 3, 0);
is ($frame->get('label'), undef);

__END__

Copyright (C) 2003, 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

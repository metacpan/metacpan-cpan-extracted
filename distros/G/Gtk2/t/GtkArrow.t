#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 3, noinit => 1;

# $Id$

# From Ross' original test.

my $arrow = Gtk2::Arrow -> new('up', 'none');
isa_ok($arrow, 'Gtk2::Arrow');

is_deeply([$arrow -> get(qw/arrow-type shadow-type/)],
          ['up', 'none'],
          '$arrow->new, verify');

$arrow -> set('down', 'in');

is_deeply([$arrow -> get(qw/arrow-type shadow-type/)],
          ['down', 'in'],
          '$arrow->set, verify');

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

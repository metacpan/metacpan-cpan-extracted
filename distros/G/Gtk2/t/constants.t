#!/usr/bin/perl
use strict;
use warnings;
use Gtk2 qw/:constants/;
use Gtk2::TestHelper tests => 8, noinit => 1;

my @constants = qw/GDK_CURRENT_TIME
                   GDK_PRIORITY_EVENTS
                   GDK_PRIORITY_REDRAW
                   GTK_PRIORITY_RESIZE/;
my $number = qr/^\d+$/;
foreach my $constant (@constants) {
  like (eval "Gtk2::$constant", $number);
  like (eval "$constant", $number);
}

__END__

Copyright (C) 2003-2013 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

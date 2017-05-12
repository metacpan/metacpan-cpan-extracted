#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

eval "use Gtk2 ':constants', 1.00;";
is ($@, '');

eval "use Gtk2 '-non-existent-flag', 10.00;";
like ($@, qr/this is only version/);

__END__

Copyright (C) 2008 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

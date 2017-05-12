#!/usr/bin/perl
#
# test the constants exported by Glib.
#
use strict;
use warnings;

use Glib qw(:constants);
use Test::More tests => 9;

ok(TRUE, "TRUE");
ok(!FALSE, "FALSE");

ok(
	G_PRIORITY_HIGH < G_PRIORITY_DEFAULT,
	"G_PRIORITY_HIGH < G_PRIORITY_DEFAULT"
);
ok(
	G_PRIORITY_DEFAULT < G_PRIORITY_HIGH_IDLE,
	"G_PRIORITY_DEFAULT < G_PRIORITY_HIGH_IDLE"
);
ok(
	G_PRIORITY_HIGH_IDLE < G_PRIORITY_DEFAULT_IDLE,
	"G_PRIORITY_HIGH_IDLE < G_PRIORITY_DEFAULT_IDLE"
);
ok(
	G_PRIORITY_DEFAULT_IDLE < G_PRIORITY_LOW,
	"G_PRIORITY_DEFAULT_IDLE < G_PRIORITY_LOW"
);

my $rw = G_PARAM_READWRITE;
is_deeply(
	[ sort @{ $rw } ],
	['readable', 'writable'],
	"G_PARAM_READWRITE"
);


ok(SOURCE_CONTINUE, "SOURCE_CONTINUE");
ok(!SOURCE_REMOVE, "SOURCE_REMOVE");

__END__

Copyright (C) 2003-2012 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

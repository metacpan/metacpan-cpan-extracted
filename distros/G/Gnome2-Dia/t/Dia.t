#!/usr/bin/perl -w
use strict;
use Test::More tests => 6;

# $Id$

###############################################################################

use_ok("Gnome2::Dia");

my ($x, $y, $z) = Gnome2::Dia -> GET_VERSION_INFO();
my $number = qr/^\d+$/;

like($x, $number);
like($y, $number);
like($z, $number);

ok(Gnome2::Dia -> CHECK_VERSION(0, 0, 0));
ok(!Gnome2::Dia -> CHECK_VERSION(100, 100, 100));

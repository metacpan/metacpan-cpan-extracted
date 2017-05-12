#!/usr/bin/perl

# Testing the :skip_all import flag

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use LWP::Online ':skip_all';

# This should only ever run if we are online
use Test::More tests => 1;
my $online = LWP::Online::online();
ok( $online, 'Confirmed tests only run if online' );

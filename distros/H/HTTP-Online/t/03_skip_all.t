#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use HTTP::Online ':skip_all';
use Test::More tests => 1;

# We should be online if we got past :skip_all
ok( HTTP::Online->new->online, '->online ok' );

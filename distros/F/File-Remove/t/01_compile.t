#!/usr/bin/perl

# Tests that File::Remove compiles ok

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;

use_ok( 'File::Remove' );

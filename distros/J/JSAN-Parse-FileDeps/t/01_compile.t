#!/usr/bin/perl -w

# Compile testing for JSAN::Parse::FileDeps

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.005, "Your perl is new enough" );
use_ok('JSAN::Parse::FileDeps');

exit(0);

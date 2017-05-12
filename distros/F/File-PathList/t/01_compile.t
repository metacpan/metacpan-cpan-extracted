#!/usr/bin/perl

# Load testing for File::PathList

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.005, "Your perl is new enough" );

use_ok( 'File::PathList' );

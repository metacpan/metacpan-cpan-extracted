#!/usr/bin/perl -w

# Load test the Digest::TransformPath module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}





# Does everything load?
use Test::More 'tests' => 2;
ok( $] > 5.005, 'Your perl is new enough' );
use_ok('Digest::TransformPath');

1;

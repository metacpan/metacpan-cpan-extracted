#!/usr/bin/perl

# Compile-testing for File::BLOB

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;

use_ok( 'File::BLOB' );

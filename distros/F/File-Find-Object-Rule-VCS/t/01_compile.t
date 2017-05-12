#!/usr/bin/perl

# Load testing for File::Find::Rule::VCS

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

# Check their perl version
ok( $] >= 5.00503, "Your perl is new enough" );

# Load the modules
use_ok( 'File::Find::Object::Rule::VCS' );

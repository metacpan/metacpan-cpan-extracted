#!/usr/bin/perl

# Compile testing for JSAN::Librarian

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
use_ok('JSAN::Librarian::Book');
use_ok('JSAN::Librarian::Library');
use_ok('JSAN::Librarian');

#!/usr/bin/perl

# Compile testing for jsan

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::Script;

# Does the module load
use_ok('JSAN::Shell');

# Does the jsan script compile
script_compiles( 'script/jsan' );

#!/usr/bin/perl

# Load testing for File::LocalizeNewlines

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] >= 5.005, "Your perl is new enough" );

use_ok( 'File::LocalizeNewlines' );

script_compiles_ok( 'script/localizenewlines' );

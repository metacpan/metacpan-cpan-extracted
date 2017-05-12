#!/usr/bin/perl -w

# Compile testing for HTML::Email::Obfuscate

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.005, "Your perl is new enough" );
use_ok('HTML::Email::Obfuscate');

exit(0);

#!/usr/bin/env perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::SiteTear' );
}

diag( "Testing HTML::SiteTear $HTML::SiteTear::VERSION, Perl $], $^X" );

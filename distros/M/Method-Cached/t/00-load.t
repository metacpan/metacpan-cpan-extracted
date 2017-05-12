#!/usr/bin/env perl

use strict;
use Test::More tests => 1;

BEGIN {
	use_ok( 'Method::Cached' );
}

diag( "Testing Method::Cached $Method::Cached::VERSION, Perl $], $^X" );

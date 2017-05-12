#!/usr/bin/env  perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Dynamic::Loader' );
}

diag( "Testing Dynamic::Loader $Dynamic::Loader::VERSION, Perl $], $^X" );

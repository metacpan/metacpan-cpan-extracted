#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Layout::Manager' );
}

diag( "Testing Layout::Manager $Layout::Manager::VERSION, Perl $], $^X" );

#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Directory::Deploy' );
}

diag( "Testing Directory::Deploy $Directory::Deploy::VERSION, Perl $], $^X" );

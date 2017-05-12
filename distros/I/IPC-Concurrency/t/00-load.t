#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'IPC::Concurrency' );
}

diag( "Testing IPC::Concurrency $IPC::Concurrency::VERSION, Perl $], $^X" );

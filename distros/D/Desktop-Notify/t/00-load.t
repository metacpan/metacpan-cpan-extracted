#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Desktop::Notify' );
}

diag( "Testing Desktop::Notify $Desktop::Notify::VERSION, Perl $], $^X" );

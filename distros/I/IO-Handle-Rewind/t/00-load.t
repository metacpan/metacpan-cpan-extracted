#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'IO::Handle::Rewind' );
}

diag( "Testing IO::Handle::Rewind $IO::Handle::Rewind::VERSION, Perl $], $^X" );

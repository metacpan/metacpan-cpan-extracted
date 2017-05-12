#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Event::Schedule' );
}

diag( "Testing Event::Schedule $Event::Schedule::VERSION, Perl $], $^X" );

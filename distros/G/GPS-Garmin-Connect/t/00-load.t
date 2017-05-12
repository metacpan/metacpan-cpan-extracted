#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'GPS::Garmin::Connect' );
}

diag( "Testing GPS::Garmin::Connect $GPS::Garmin::Connect::VERSION, Perl $], $^X" );

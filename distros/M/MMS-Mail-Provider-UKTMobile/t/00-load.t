#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MMS::Mail::Provider::UKTMobile' );
}

diag( "Testing MMS::Mail::Provider::UKTMobile $MMS::Mail::Provider::UKTMobile::VERSION, Perl $], $^X" );

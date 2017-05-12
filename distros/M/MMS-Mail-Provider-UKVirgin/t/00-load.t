#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MMS::Mail::Provider::UKVirgin' );
}

diag( "Testing MMS::Mail::Provider::UKVirgin $MMS::Mail::Provider::UKVirgin::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MMS::Mail::Provider::UK3' );
}

diag( "Testing MMS::Mail::Provider::UK3 $MMS::Mail::Provider::UK3::VERSION, Perl $], $^X" );

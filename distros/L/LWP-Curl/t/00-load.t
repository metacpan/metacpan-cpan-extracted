#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'LWP::Curl' );
}

diag( "Testing LWP::Curl $LWP::Curl::VERSION, Perl $], $^X" );

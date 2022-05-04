#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Method::Signatures::Simple::ParseKeyword' );
}

diag( "Testing Method::Signatures::Simple::ParseKeyword $Method::Signatures::Simple::ParseKeyword::VERSION, Perl $], $^X" );

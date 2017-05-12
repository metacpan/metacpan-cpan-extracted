#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Lingua::ZH::Summary' );
}

diag( "Testing Lingua::ZH::Summary $Lingua::ZH::Summary::VERSION, Perl $], $^X" );

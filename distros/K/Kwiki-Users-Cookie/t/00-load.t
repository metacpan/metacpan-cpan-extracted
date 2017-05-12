#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::Users::Cookie' );
}

diag( "Testing Kwiki::Users::Cookie $Kwiki::Users::Cookie::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::JSON' );
}

diag( "Testing Kwiki::JSON $Kwiki::JSON::VERSION, Perl $], $^X" );

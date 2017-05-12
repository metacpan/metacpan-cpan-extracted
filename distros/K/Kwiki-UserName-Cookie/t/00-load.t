#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::UserName::Cookie' );
}

diag( "Testing Kwiki::UserName::Cookie $Kwiki::UserName::Cookie::VERSION, Perl $], $^X" );

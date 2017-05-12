#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Error::Exception' );
	use_ok( 'Error::Exception::Class' );
}

diag( "Testing Error::Exception $Error::Exception::VERSION, Perl $], $^X" );

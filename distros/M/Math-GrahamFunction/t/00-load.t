#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Math::GrahamFunction' );
}

diag( "Testing Math::GrahamFunction $Math::GrahamFunction::VERSION, Perl $], $^X" );

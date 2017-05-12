#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::Truncate' );
}

diag( "Testing HTML::Truncate $HTML::Truncate::VERSION, Perl $], $^X" );

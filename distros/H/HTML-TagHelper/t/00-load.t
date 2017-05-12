#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::TagHelper' );
}

diag( "Testing HTML::TagHelper $HTML::TagHelper::VERSION, Perl $], $^X" );

1;
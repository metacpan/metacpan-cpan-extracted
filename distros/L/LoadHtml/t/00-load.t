#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'LoadHtml' );
}

diag( "Testing LoadHtml $LoadHtml::VERSION, Perl $], $^X" );

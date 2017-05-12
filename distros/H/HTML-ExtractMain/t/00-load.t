#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::ExtractMain' );
}

diag( "Testing HTML::ExtractMain $HTML::ExtractMain::VERSION, Perl $], $^X" );

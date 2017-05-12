#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::Socialtext' );
}

diag( "Testing HTML::WikiConverter::Socialtext $HTML::WikiConverter::Socialtext::VERSION, Perl $], $^X" );

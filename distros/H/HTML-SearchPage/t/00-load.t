#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'HTML::SearchPage' );
	use_ok( 'HTML::SearchPage::Param' );
	use_ok( 'HTML::SearchPage::Files' );
	use_ok( 'HTML::SearchPage::Tutorial' );
}

diag( "Testing HTML::SearchPage $HTML::SearchPage::VERSION, Perl $], $^X" );

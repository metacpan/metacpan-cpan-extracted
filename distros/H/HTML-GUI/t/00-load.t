#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'HTML::GUI::widget' );
	use_ok( 'HTML::GUI::text' );
	use_ok( 'HTML::GUI::screen' );
}

diag( "Testing HTML::GUI::widget $HTML::GUI::widget::VERSION, Perl $], $^X" );

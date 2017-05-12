#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Icon::Theme::List' );
}

diag( "Testing Icon::Theme::List $Icon::Theme::List::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'JS::YUI::Loader' );
}

diag( "Testing JS::YUI::Loader $JS::YUI::Loader::VERSION, Perl $], $^X" );

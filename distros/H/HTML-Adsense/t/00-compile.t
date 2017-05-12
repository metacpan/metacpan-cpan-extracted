#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::Adsense' );
}

diag( "Testing HTML::Adsense $HTML::Adsense::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::Theme::BlueOcean' );
}

diag( "Testing Kwiki::Theme::BlueOcean $Kwiki::Theme::BlueOcean::VERSION, Perl $], $^X" );

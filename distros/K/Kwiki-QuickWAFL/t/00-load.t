#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::QuickWAFL' );
}

diag( "Testing Kwiki::QuickWAFL $Kwiki::QuickWAFL::VERSION, Perl $], $^X" );

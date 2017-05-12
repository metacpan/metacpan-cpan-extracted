#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::JSLog' );
}

diag( "Testing Kwiki::JSLog $Kwiki::JSLog::VERSION, Perl $], $^X" );

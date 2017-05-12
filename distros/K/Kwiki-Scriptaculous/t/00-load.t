#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::Scriptaculous' );
}

diag( "Testing Kwiki::Scriptaculous $Kwiki::Scriptaculous::VERSION, Perl $], $^X" );

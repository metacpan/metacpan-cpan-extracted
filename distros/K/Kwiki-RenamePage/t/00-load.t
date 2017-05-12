#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::RenamePage' );
}

diag( "Testing Kwiki::RenamePage $Kwiki::RenamePage::VERSION, Perl $], $^X" );

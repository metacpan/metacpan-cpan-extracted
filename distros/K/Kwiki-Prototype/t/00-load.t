#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::Prototype' );
}

diag( "Testing Kwiki::Prototype $Kwiki::Prototype::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ExportTo' );
}

diag( "Testing ExportTo $ExportTo::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Document::Maker' );
}

diag( "Testing Document::Maker $Document::Maker::VERSION, Perl $], $^X" );

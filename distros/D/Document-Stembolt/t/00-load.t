#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Document::Stembolt' );
}

diag( "Testing Document::Stembolt $Document::Stembolt::VERSION, Perl $], $^X" );

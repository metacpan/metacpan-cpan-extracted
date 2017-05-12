#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Document::Writer' );
	use_ok( 'Document::Writer::Page' );
}

diag( "Testing Document::Writer $Document::Writer::VERSION, Perl $], $^X" );

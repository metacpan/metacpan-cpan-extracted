#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::TableOfContents::Print' );
}

diag( "Testing Kwiki::TableOfContents::Print $Kwiki::TableOfContents::Print::VERSION, Perl $], $^X" );

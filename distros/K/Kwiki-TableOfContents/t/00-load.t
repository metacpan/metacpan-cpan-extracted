#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::TableOfContents' );
}

diag( "Testing Kwiki::TableOfContents $Kwiki::TableOfContents::VERSION, Perl $], $^X" );

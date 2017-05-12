#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::Edit::ContentionManagement' );
}

diag( "Testing Kwiki::Edit::ContentionManagement $Kwiki::Edit::ContentionManagement::VERSION, Perl $], $^X" );

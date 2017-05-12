#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::Edit::BackgroundSave' );
}

diag( "Testing Kwiki::Edit::BackgroundSave $Kwiki::Edit::BackgroundSave::VERSION, Perl $], $^X" );

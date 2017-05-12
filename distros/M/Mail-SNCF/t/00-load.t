#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Mail::SNCF' );
	use_ok( 'Mail::SNCF::Remind' );
	use_ok( 'Mail::SNCF::ICal' );
	use_ok( 'Mail::SNCF::Text' );
}

diag( "Testing Mail::SNCF $Mail::SNCF::VERSION, Perl $], $^X" );

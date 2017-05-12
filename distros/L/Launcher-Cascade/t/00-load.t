#!perl -T

use Test::More tests => 10;

BEGIN {
	use_ok( 'Launcher::Cascade' );
	use_ok( 'Launcher::Cascade::Base' );
	use_ok( 'Launcher::Cascade::Simple' );
	use_ok( 'Launcher::Cascade::Container' );
	use_ok( 'Launcher::Cascade::FileReader' );
	use_ok( 'Launcher::Cascade::FileReader::Seekable' );
	use_ok( 'Launcher::Cascade::Printable' );
	use_ok( 'Launcher::Cascade::ListOfStrings' );
	use_ok( 'Launcher::Cascade::ListOfStrings::Errors' );
	use_ok( 'Launcher::Cascade::ListOfStrings::Context' );
}

diag( "Testing Launcher::Cascade $Launcher::Cascade::VERSION, Perl $], $^X" );

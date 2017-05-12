#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Fedora::App::MaintainerTools' );
}

diag( "Testing Fedora::App::MaintainerTools $Fedora::App::MaintainerTools::VERSION, Perl $], $^X" );

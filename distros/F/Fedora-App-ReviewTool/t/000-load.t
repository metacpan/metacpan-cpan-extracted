#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Fedora::App::ReviewTool' );
}

diag( "Testing Fedora::App::ReviewTool $Fedora::App::ReviewTool::VERSION, Perl $], $^X" );

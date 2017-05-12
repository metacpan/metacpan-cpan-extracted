#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Jifty::Plugin::ModelMap' );
}

diag( "Testing Jifty::Plugin::ModelMap $Jifty::Plugin::ModelMap::VERSION, Perl $], $^X" );

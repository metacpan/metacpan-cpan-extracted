#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'GD::Icons' );
	use_ok( 'GD::Icons::Config' );
}

diag( "Testing GD::Icons $GD::Icons::VERSION, Perl $], $^X" );

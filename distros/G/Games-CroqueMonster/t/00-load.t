#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Games::CroqueMonster' );
}

diag( "Testing Games::CroqueMonster $Games::CroqueMonster::VERSION, Perl $], $^X" );

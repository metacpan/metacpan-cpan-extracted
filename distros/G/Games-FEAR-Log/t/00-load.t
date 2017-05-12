#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Games::FEAR::Log' );
}

diag( "Testing Games::FEAR::Log $Games::FEAR::Log::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Games::Jumble' );
}

diag( "Testing Games::Jumble $Games::Jumble::VERSION, Perl $], $^X" );

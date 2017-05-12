#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Ham::Reference::Qsignals' );
}

diag( "Testing Ham::Reference::Qsignals $Ham::Reference::Qsignals::VERSION, Perl $], $^X" );

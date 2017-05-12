#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Lingua::EN::AffectiveNorms' );
}

diag( "Testing Lingua::EN::AffectiveNorms $Lingua::EN::AffectiveNorms::VERSION, Perl $], $^X" );

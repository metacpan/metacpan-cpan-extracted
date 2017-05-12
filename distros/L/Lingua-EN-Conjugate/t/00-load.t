#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Lingua::EN::Conjugate' );
}

diag( "Testing Lingua::EN::Conjugate $Lingua::EN::Conjugate::VERSION, Perl $], $^X" );

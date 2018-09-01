#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ELF::sign' );
}

diag( "Testing ELF::sign $POE::Filter::SSL::VERSION, Perl $], $^X" );

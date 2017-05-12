#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Devel::file' );
}

diag( "Testing Devel::file $Devel::file::VERSION, Perl $], $^X" );

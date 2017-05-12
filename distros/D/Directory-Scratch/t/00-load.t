#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Directory::Scratch' );
}

diag( "Testing Directory::Scratch $Directory::Scratch::VERSION, Perl $], $^X" );

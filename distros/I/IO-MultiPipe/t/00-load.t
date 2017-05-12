#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'IO::MultiPipe' );
}

diag( "Testing IO::MultiPipe $IO::MultiPipe::VERSION, Perl $], $^X" );

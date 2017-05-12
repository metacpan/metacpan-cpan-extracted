#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Devel::Backtrace' );
}

diag( "Testing Devel::Backtrace $Devel::Backtrace::VERSION, Perl $], $^X" );

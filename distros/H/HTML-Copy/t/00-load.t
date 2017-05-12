#!perl -T
use 5.008;
use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::Copy' );
}

diag( "Testing HTML::Copy $HTML::Copy::VERSION, Perl $], $^X" );

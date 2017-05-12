#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::Miner' );
}

diag( "Testing HTML::Miner $HTML::Miner::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Decision::ParseTree' );
}

diag( "Testing Decision::ParseTree $Decision::ParseTree::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Graph::Reader::LoadClassHierarchy' );
}

diag( "Testing Graph::Reader::LoadClassHierarchy $Graph::Reader::LoadClassHierarchy::VERSION, Perl $], $^X" );

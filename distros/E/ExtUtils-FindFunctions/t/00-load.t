#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ExtUtils::FindFunctions' );
}

diag( "Testing ExtUtils::FindFunctions $ExtUtils::FindFunctions::VERSION, Perl $], $^X" );

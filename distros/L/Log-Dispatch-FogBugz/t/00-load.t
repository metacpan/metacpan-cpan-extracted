#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Log::Dispatch::FogBugz' );
}

diag( "Testing Log::Dispatch::FogBugz $Log::Dispatch::FogBugz::VERSION, Perl $], $^X" );

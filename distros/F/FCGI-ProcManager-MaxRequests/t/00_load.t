#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FCGI::ProcManager::MaxRequests' );
}

diag( "Testing FCGI::ProcManager::MaxRequests $FCGI::ProcManager::MaxRequests::VERSION, Perl $], $^X" );

use Test::More tests => 1;

BEGIN {
use_ok( 'FCGI::EV' );
}

diag( "Testing FCGI::EV $FCGI::EV::VERSION" );

use Test::More tests => 2;

BEGIN {
use_ok( 'FCGI::EV::Std' );
use_ok( 'FCGI::EV::Std::Nonblock' );
}

diag( "Testing FCGI::EV::Std $FCGI::EV::Std::VERSION" );

#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'FWS::V2::SocketLabs' ) || print "Bail out!\n";
}

diag( "Testing FWS::V2::SocketLabs $FWS::V2::SocketLabs::VERSION, Perl $], $^X" );

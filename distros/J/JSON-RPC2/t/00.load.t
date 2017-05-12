use Test::More tests => 3;

BEGIN {
use_ok( 'JSON::RPC2' );
use_ok( 'JSON::RPC2::Client' );
use_ok( 'JSON::RPC2::Server' );
}

diag( "Testing JSON::RPC2 $JSON::RPC2::VERSION" );

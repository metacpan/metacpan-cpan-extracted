use Test::More tests => 5;

BEGIN {
use_ok( 'Inferno::RegMgr' );
use_ok( 'Inferno::RegMgr::TCP' );
use_ok( 'Inferno::RegMgr::Service' );
use_ok( 'Inferno::RegMgr::Lookup' );
use_ok( 'Inferno::RegMgr::Monitor' );
}

diag( "Testing Inferno::RegMgr $Inferno::RegMgr::VERSION" );

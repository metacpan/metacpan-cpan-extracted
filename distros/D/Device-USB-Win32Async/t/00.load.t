use Test::More tests => 1;

BEGIN {
use Device::USB::Device;
use_ok( 'Device::USB::Win32Async' );
}

diag( "Testing Device::USB::Win32Async $Device::USB::Win32Async::VERSION" );

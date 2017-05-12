use Test::Simple tests => 3;

use Device::USB::PCSensor::HidTEMPer::Device;

ok( Device::USB::PCSensor::HidTEMPer::Device::CONNECTION_TIMEOUT eq 60, 'CONNECTION_TIMEOUT');
ok( !defined(Device::USB::PCSensor::HidTEMPer::Device::_write( undef, 0x69 )), 'Upper write limit' );
ok( !defined(Device::USB::PCSensor::HidTEMPer::Device::_write( undef, 0x60 )), 'Lower write limit' );

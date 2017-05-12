use Test::Simple tests => 3;

use Device::USB::PCSensor::HidTEMPer;

ok(Device::USB::PCSensor::HidTEMPer::VENDOR_ID eq 0x1130, 'VENDOR_ID');
ok(Device::USB::PCSensor::HidTEMPer::PRODUCT_ID eq 0x660c, 'PRODUCT_ID');

my $pcsensor = Device::USB::PCSensor::HidTEMPer->new();

ok( defined($pcsensor), 'new()');
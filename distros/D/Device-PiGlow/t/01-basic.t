use Test::More qw(no_plan);

use strict;
use warnings;

use Device::PiGlow;

ok(my $dp = Device::PiGlow->new(), "create a Device::PiGlow");
is($dp->I2CBusDevicePath, '/dev/i2c-1', "got the right path");
is($dp->I2CDeviceAddress, 0x54, "got the address right");
isa_ok($dp->device_smbus(), "Device::SMBus");

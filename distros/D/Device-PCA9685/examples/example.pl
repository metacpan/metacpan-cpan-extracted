use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Device::PWMGenerator::PCA9685;

my $dev = Device::PWMGenerator::PCA9685->new(
    I2CBusDevicePath => '/dev/i2c-1',
    debug            => 1,
    frequency        => 400,
);
$dev->enable();
$dev->setChannelPWM(4,0,10);
sleep(1);
$dev->setChannelPWM(4,0,2048);
sleep(1);
$dev->setChannelPWM(4,0,2748);
sleep(1);
$dev->setChannelPWM(4,0,10);


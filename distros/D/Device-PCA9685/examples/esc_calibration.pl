
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

# Calibrate max duty cycle as 3600 and min(point at which esv cut off at 700

my $dutycycle = 3600;
$dev->setChannelPWM(4,0,$dutycycle);
$dev->setChannelPWM(5,0,$dutycycle);
$dev->setChannelPWM(6,0,$dutycycle);
$dev->setChannelPWM(7,0,$dutycycle);
sleep(2);
my $dutycycle = 700;
$dev->setChannelPWM(4,0,$dutycycle);
$dev->setChannelPWM(5,0,$dutycycle);
$dev->setChannelPWM(6,0,$dutycycle);
$dev->setChannelPWM(7,0,$dutycycle);

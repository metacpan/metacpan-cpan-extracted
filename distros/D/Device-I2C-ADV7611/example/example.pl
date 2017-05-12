use FindBin qw($Bin);
use lib "$Bin/../lib";
use v5.10;

use Device::I2C::ADV7611;
use Fcntl;

my $dev = Device::I2C::ADV7611->new('/dev/i2c-1', O_RDWR);
$dev->resetDevice();

print $dev->checkCable();


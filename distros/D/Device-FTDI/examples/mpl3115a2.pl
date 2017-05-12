use strict;
use warnings;

use Device::FTDI::I2C;

my $i2c = Device::FTDI::I2C->new(
    clock_rate => 100E3,
);

sleep 0.1;

my $addr = 0x60;

# Read the ID register
my $id = unpack "C",
    $i2c->write_then_read( $addr, pack( "C", 0x0C ), 1 )->get;

# Start a oneshot operation
$i2c->write( $addr, pack( "C C", 0x26, 0x02 ) )->get;

sleep 0.2;

# Read the current temperature
my $temp = unpack "n",
    $i2c->write_then_read( $addr, pack( "C", 0x04 ), 2 )->get;
printf "OUT_T register is %04x\n", $temp;
printf "  temperature is %.2f\n", $temp / 256;

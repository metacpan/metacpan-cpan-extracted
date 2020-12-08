#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::MCP23S17;
use Device::Chip::Adapter;

use Time::HiRes qw( sleep );

use Future::AsyncAwait;

use Getopt::Long;

GetOptions(
   'adapter|A=s' => \my $ADAPTER,
   'mount|M=s'   => \my $MOUNTPARAMS,
) or exit 1;

my $chip = Device::Chip::MCP23S17->new;
await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ), $MOUNTPARAMS,
);

await $chip->protocol->power(1);

await $chip->reset;

await $chip->set_input_polarity( 0xFF, 0xFF );

foreach my $byte ( 0 .. 255 ) {
   # write a byte to the B port
   await $chip->write_gpio( $byte << 8, 0xff << 8 );

   # read the A port
   my $in = await $chip->read_gpio( 0xff );
   printf "GPA is 0b%08b\n", $in;

   sleep 0.1;
}

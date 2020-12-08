#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::NoritakeGU_D;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Getopt::Long qw( :config no_ignore_case );
use Time::HiRes qw( sleep );

GetOptions(
   'i|interface=s' => \(my $INTERFACE = "I2C"),
   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::NoritakeGU_D->new( interface => $INTERFACE );

await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
);

await $chip->power(1);

await $chip->initialise;

use constant CHAR_PER_LINE => 12;

# Count on bottom three bits, read the top one

await $chip->set_gpio_direction( 0x7 );

my $x = 0;
while(1) {
   await $chip->write_gpio( $x++ );
   sleep 0.05;

   my $in = await $chip->read_gpio;
   print "P03 ", $in & 0x8 ? "HIGH" : "low", "\n";
}

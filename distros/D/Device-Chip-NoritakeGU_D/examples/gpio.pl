#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::NoritakeGU_D;
use Device::Chip::Adapter;
use Getopt::Long qw( :config no_ignore_case );
use Time::HiRes qw( sleep );

GetOptions(
   'i|interface=s' => \(my $INTERFACE = "I2C"),
   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::NoritakeGU_D->new( interface => $INTERFACE );

$chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
)->get;

$chip->power(1)->get;

$chip->initialise->get;

use constant CHAR_PER_LINE => 12;

# Count on bottom three bits, read the top one

$chip->set_gpio_direction( 0x7 )->get;

my $x = 0;
while(1) {
   $chip->write_gpio( $x++ )->get;
   sleep 0.05;

   my $in = $chip->read_gpio->get;
   print "P03 ", $in & 0x8 ? "HIGH" : "low", "\n";
}

#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::MCP23S17;
use Device::Chip::Adapter;

use Time::HiRes qw( sleep );

use Getopt::Long;

GetOptions(
   'adapter|A=s' => \( my $ADAPTER = "BusPirate" ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::MCP23S17->new;
$chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ), $MOUNTPARAMS,
)->get;

$chip->protocol->power(1)->get;

$chip->reset->get;

$chip->set_input_polarity( 0xFF, 0xFF )->get;

foreach my $byte ( 0 .. 255 ) {
   # write a byte to the B port
   $chip->write_gpio( $byte << 8, 0xff << 8 )->get;

   # read the A port
   my $in = $chip->read_gpio( 0xff )->get;
   printf "GPA is 0b%08b\n", $in;

   sleep 0.1;
}

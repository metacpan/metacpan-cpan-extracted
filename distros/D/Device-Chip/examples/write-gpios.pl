#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes qw( sleep );
use Getopt::Long;

use Device::Chip::Adapter;

GetOptions(
   'adapter|A=s' => \( my $ADAPTER ),
) or exit 1;

my $adapter = Device::Chip::Adapter->new_from_description( $ADAPTER );
my $proto = $adapter->make_protocol( "GPIO" )->get;

my @gpios = $proto->list_gpios;

while(1) {
   foreach my $gpio ( @gpios ) {
      print "$gpio HI\n";
      $proto->write_gpios( { $gpio => 1 } )->get;

      sleep 0.5;

      print "$gpio LO\n";
      $proto->write_gpios( { $gpio => 0 } )->get;

      sleep 0.5;
   }
}

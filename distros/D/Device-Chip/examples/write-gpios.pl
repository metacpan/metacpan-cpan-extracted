#!/usr/bin/perl

use v5.26;
use warnings;

use Time::HiRes qw( sleep );
use Getopt::Long;

use Future::AsyncAwait 0.47;

use Device::Chip::Adapter;

GetOptions(
   'adapter|A=s' => \( my $ADAPTER ),
) or exit 1;

my $adapter = Device::Chip::Adapter->new_from_description( $ADAPTER );
my $proto = await $adapter->make_protocol( "GPIO" );

my @gpios = $proto->list_gpios;

while(1) {
   foreach my $gpio ( @gpios ) {
      print "$gpio HI\n";
      await $proto->write_gpios( { $gpio => 1 } );

      sleep 0.5;

      print "$gpio LO\n";
      await $proto->write_gpios( { $gpio => 0 } );

      sleep 0.5;
   }
}

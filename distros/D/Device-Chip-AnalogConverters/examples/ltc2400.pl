#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::LTC2400;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Getopt::Long;

GetOptions(
   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::LTC2400->new;
await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
);

await $chip->protocol->power(1);

my $RANGE = 4.096;

while(1) {
   my $reading = await $chip->read_adc;

   my $value = $reading->{VALUE};
   $value += 2 ** 24 if $reading->{EXR};

   $value *= $RANGE / (2 ** 24);
   $value = -$value if !$reading->{SIG};

   printf "Reading: %0.6fV\n", $value;
   sleep 1;
}

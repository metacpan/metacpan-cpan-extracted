#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::PCF8574;
use Device::Chip::Adapter;

use Time::HiRes qw( sleep );

use Future::AsyncAwait;

use Getopt::Long;

GetOptions(
   'adapter|A=s' => \my $ADAPTER,
   'mount|M=s'   => \my $MOUNTPARAMS,

   'invert|i' => \my $INVERT,
) or exit 1;

my $chip = Device::Chip::PCF8574->new;
await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ), $MOUNTPARAMS,
);

await $chip->protocol->power(1);

END { $chip->protocol->power(0)->get; }
$SIG{INT} = $SIG{TERM} = sub { exit 1 };

while(1) {
   my $bits = await $chip->read;
   $bits ^= 0xff if $INVERT;

   printf "Read %02x\n", $bits;

   sleep 0.1;
}

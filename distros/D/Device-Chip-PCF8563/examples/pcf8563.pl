#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::PCF8563;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Getopt::Long;

GetOptions(
   's|set-to-now' => \my $SET_TO_NOW,

   'adapter|A=s' => \my $ADAPTER,
) or exit 1;

my $chip = Device::Chip::PCF8563->new;
await $chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

await $chip->protocol->power(1);

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
#   $chip and $chip->power(0)->get;
}

if( $SET_TO_NOW ) {
   await $chip->write_time( localtime );
}

use POSIX qw( mktime );
print "The time on the PCF8563 is ",
   scalar( localtime mktime await $chip->read_time ),
   "\n";

#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::PCF8574;
use Device::Chip::Adapter;

use Time::HiRes qw( sleep );

use Getopt::Long;

GetOptions(
   'adapter|A=s' => \( my $ADAPTER = "BusPirate" ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::PCF8574->new;
$chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ), $MOUNTPARAMS,
)->get;

$chip->protocol->power(1)->get;

END { $chip->protocol->power(0)->get; }
$SIG{INT} = $SIG{TERM} = sub { exit 1 };

while(1) {
   printf "Read %02x\n", $chip->read()->get;

   sleep 0.1;
}

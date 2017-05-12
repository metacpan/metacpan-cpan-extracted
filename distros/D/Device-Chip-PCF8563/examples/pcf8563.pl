#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::PCF8563;
use Device::Chip::Adapter;
use Getopt::Long;

GetOptions(
   's|set-to-now' => \my $SET_TO_NOW,

   'adapter|A=s' => \( my $ADAPTER = "FTDI" ),
) or exit 1;

my $chip = Device::Chip::PCF8563->new;
$chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
)->get;

$chip->protocol->power(1)->get;

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
#   $chip and $chip->power(0)->get;
}

if( $SET_TO_NOW ) {
   $chip->write_time( localtime )->get;
}

use POSIX qw( mktime );
print "The time on the PCF8563 is ",
   scalar( localtime mktime $chip->read_time->get ),
   "\n";

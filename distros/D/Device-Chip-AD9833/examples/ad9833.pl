#!/usr/bin/perl

use v5.14;
use warnings;

use Device::Chip::AD9833;
use Device::Chip::Adapter;

use Getopt::Long;

GetOptions(
   'adapter|A=s' => \my $ADAPTER,

   'freq|F=s', => \( my $FREQ = 400 ),
   'wave|w=s', => \( my $WAVE = "sine" ),
) or exit 1;

my $chip = Device::Chip::AD9833->new;
$chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
)->get;

$chip->protocol->power(1)->get;

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   #$chip and $chip->protocol->power(0)->get;
}

my $REG_FREQ0 = ( $FREQ << 28 ) / 25E6;

$chip->init->get;

$chip->change_config( wave => $WAVE )->get;
$chip->write_FREQ0( $REG_FREQ0 )->get;
$chip->write_PHASE0( 0 )->get;

print "Done\n";

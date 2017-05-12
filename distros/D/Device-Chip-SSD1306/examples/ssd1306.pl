#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::Adapter;

use Getopt::Long;
use Time::HiRes qw( sleep );

GetOptions(
   'i|interface=s' => \(my $INTERFACE = "SPI4"),
   'm|model=s'   => \( my $MODEL ),
   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $cls = "Device::Chip::SSD1306::$INTERFACE";
require ( "$cls.pm" =~ s{::}{/}gr );

my $chip = $cls->new(
   model => $MODEL,
);
$chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
)->get;

$chip->power(1)->get;

# Let power stablise for 100msec
sleep 0.1;

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   $chip and $chip->display( 0 )->get;
   $chip and $chip->power(0)->get;
}

$chip->init->get;

$chip->display( 1 )->get;
$chip->display_lamptest( 1 )->get;

sleep 3;

$chip->display_lamptest( 0 )->get;

my $display = [
   map { [ ( 0 ) x $chip->columns ] } 1 .. $chip->rows
];

my $maxcol = $chip->columns - 1;
my $maxrow = $chip->rows    - 1;

# Build a test pattern:

# A border
$display->[$_][      0] = 1 for 0 .. $maxrow;
$display->[$_][$maxcol] = 1 for 0 .. $maxrow;
$display->[      0][$_] = 1 for 0 .. $maxcol;
$display->[$maxrow][$_] = 1 for 0 .. $maxcol;

# A diagonal line out from the centre
my $midcol = $chip->columns / 2;
my $midrow = $chip->rows / 2;
foreach my $i ( 0 .. $midrow ) {
   $display->[$midrow-$i  ][$midcol-$i] = 1;
   $display->[$midrow+$i+1][$midcol-$i] = 1;
   $display->[$midrow-$i  ][$midcol+$i+1] = 1;
   $display->[$midrow+$i+1][$midcol+$i+1] = 1;
}

my $pixels = "";
sub _mkpixel
{
   @_ == 8 or die "Need 8 pixel values";
   my $v = 0;
   $v <<= 1, $_ && ( $v |= 1 ) for reverse @_;
   return chr $v;
}

# The byte buffer is built in pages
foreach my $page ( 0 .. ( $chip->rows / 8 ) - 1 ) {
   my $row = $page * 8;

   foreach my $col ( 0 .. $maxcol ) {
      $pixels .= _mkpixel( map { $display->[$row+$_][$col] } 0 .. 7 );
   }
}

$chip->send_display( $pixels )->get;

sleep 10;

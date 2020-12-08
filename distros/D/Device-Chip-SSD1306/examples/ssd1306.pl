#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::Adapter;

use Future::AsyncAwait;

use Getopt::Long qw( :config no_ignore_case );
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
await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
);

await $chip->power(1);

# Let power stablise for 100msec
sleep 0.1;

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   $chip and $chip->display( 0 )->get;
   $chip and $chip->power(0)->get;
}

await $chip->init;

await $chip->display( 1 );
await $chip->display_lamptest( 1 );

sleep 3;

await $chip->display_lamptest( 0 );

$chip->clear;

my $maxcol = $chip->columns - 1;
my $maxrow = $chip->rows    - 1;

# Build a test pattern:

# A border
$chip->draw_vline(       0, 0, $maxrow );
$chip->draw_vline( $maxcol, 0, $maxrow );
$chip->draw_hline( 0, $maxcol,       0 );
$chip->draw_hline( 0, $maxcol, $maxrow );

# A diagonal line out from the centre
my $midcol = $chip->columns / 2;
my $midrow = $chip->rows / 2;
foreach my $i ( 0 .. $midrow ) {
   $chip->draw_pixel( $midcol-$i,   $midrow-$i   );
   $chip->draw_pixel( $midcol-$i,   $midrow+$i+1 );
   $chip->draw_pixel( $midcol+$i+1, $midrow-$i   );
   $chip->draw_pixel( $midcol+$i+1, $midrow+$i+1 );
}

await $chip->refresh;

sleep 10;

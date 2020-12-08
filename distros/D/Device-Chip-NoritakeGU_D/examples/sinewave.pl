#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::NoritakeGU_D;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Getopt::Long qw( :config no_ignore_case );
use Time::HiRes qw( sleep );

use constant TAU => 8 * atan2(1, 1);

GetOptions(
   'i|interface=s' => \(my $INTERFACE = "I2C"),
   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::NoritakeGU_D->new( interface => $INTERFACE );

await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
);

await $chip->power(1);

await $chip->initialise;

foreach my $offset ( map { $_ * 8 } 0 .. 31 ) {
   await $chip->realtime_image_display_columns(
      map {
         my $y = 16 * ( 1 + sin +($_+$offset)*TAU/128 );

         # Put a single pixel at height $y in this column
         vec( my $buf, $y, 1 ) = 1;
         scalar reverse pack "a4", $buf
      } 0 .. 127,
   );
}

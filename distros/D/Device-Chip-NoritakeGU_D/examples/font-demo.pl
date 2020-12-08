#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::NoritakeGU_D;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Getopt::Long qw( :config no_ignore_case );
use Time::HiRes qw( sleep );

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

use constant CHAR_PER_LINE => 12;

my $base = 0x20;
LOOP: while(1) {
   await $chip->clear;
   await $chip->cursor_home;

   foreach my $line ( 0 .. 3 ) {
      await $chip->cursor_goto( 0, $line );
      my $end = $base + CHAR_PER_LINE - 1;
      $end = 0xFF if $end > 0xFF;

      print STDERR "Chars $base .. $end\n";
      await $chip->text( sprintf( "0x%02X: ", $base ) . join( "", map { chr $_ } $base .. $end ) );

      $base = $end + 1;
      last LOOP if $base > 0xFF;
   }

   <STDIN>;
}

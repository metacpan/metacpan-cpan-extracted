#!/usr/bin/perl

use v5.26;
use warnings;

use Time::HiRes qw( sleep );

use Device::Chip::BV4243;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Getopt::Long;

GetOptions(
   'adapter|A=s' => \( my $ADAPTER = "FTDI" ),
) or exit 1;

my $chip = Device::Chip::BV4243->new;
await $chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

printf "Chip identity %d (0x%04X)\n", ( await $chip->device_id ) x 2;
say "BV4243 firmware version ", await $chip->version;

await $chip->lcd_backlight( @ARGV[0,1,2] );
exit;

my @channels = await $chip->read_chan;
print "Raw tuning values are:\n";
print "  $_\n" for @channels;

my $waskey;

while(1) {
   my $key = await $chip->get_key;

   if( !$key ) {
      $waskey and
         await $chip->lcd_backlight( 0, 10, 5 );
   }
   else {
      # Clear the display
      await $chip->lcd_command( 0x01 );
      await $chip->lcd_string( "Key $key" );

      await $chip->lcd_backlight( 10, 6, 0 );
   }

   $waskey = $key;

   sleep 0.1;
}

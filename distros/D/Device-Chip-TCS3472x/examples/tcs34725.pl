#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::Adapter;
use Device::Chip::TCS3472x;

use Future::AsyncAwait;

use Getopt::Long;
use List::Util qw( min );
use Time::HiRes qw( sleep );

my $LED;

GetOptions(
   'i|interval=i'   => \(my $INTERVAL = 0.1),
   'p|print-config' => \my $PRINT_CONFIG,
   'L|led'          => sub { $LED = 1 },
   'no-led'         => sub { $LED = 0 },

   'adapter|A=s' => \my $ADAPTER,
   'mount|M=s'   => \my $MOUNTPARAMS,
) or exit 1;

my $chip = Device::Chip::TCS3472x->new;
await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ), $MOUNTPARAMS,
);

# Set LED on/off
await $chip->set_led( $LED ) if defined $LED;

await $chip->protocol->power(0);

await $chip->protocol->power(1);
END { $chip and $chip->protocol->power(0)->get; }

( await $chip->read_id ) eq "44" or
   die "Chip ID does not match TCS34725 signature\n";

# Power up
await $chip->change_config( PON => 1 );

# Enable ADCs
await $chip->change_config( AEN => 1 );

# Set any other config changes
while( @ARGV ) {
   my ( $name, $value ) = ( shift @ARGV ) =~ m/^(.*?)=(.*)$/ or next;
   await $chip->change_config( $name => $value );
}

my $config = await $chip->read_config;
if( $PRINT_CONFIG ) {
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

my $max = $config->{atime_cycles} * 1024;
$max = 65535 if $max > 65535;

while(1) {
   my ( $c, $r, $g, $b );

   printf "Clear %5d RGB<%5d %5d %5d>\n",
      ( $c, $r, $g, $b ) = await $chip->read_crgb;

   if(1) {
      $_ /= $max for $r, $g, $b;

      $_ *= 3.0 for $r, $g, $b;
      $_ = min $_, 1 for $r, $g, $b;

      printf "\e[38:2:%d:%d:%dmRGB<%5.2f%% %5.2f%% %5.2f%%>\e[m\n",
         255*$r, 255*$g, 255*$b,
         100*$r, 100*$g, 100*$b;
   }

   sleep $INTERVAL;
}

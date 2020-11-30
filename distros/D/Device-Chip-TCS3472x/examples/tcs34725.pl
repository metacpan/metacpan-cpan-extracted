#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::Adapter;
use Device::Chip::TCS3472x;

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
$chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ), $MOUNTPARAMS,
)->get;

# Set LED on/off
$chip->set_led( $LED )->get if defined $LED;

$chip->protocol->power(0)->get;

$chip->protocol->power(1)->get;
END { $chip and $chip->protocol->power(0)->get }

$chip->read_id->get eq "44" or
   die "Chip ID does not match TCS34725 signature\n";

# Power up
$chip->change_config( PON => 1 )->get;

# Enable ADCs
$chip->change_config( AEN => 1 )->get;

# Set any other config changes
while( @ARGV ) {
   my ( $name, $value ) = ( shift @ARGV ) =~ m/^(.*?)=(.*)$/ or next;
   $chip->change_config( $name => $value )->get;
}

my $config = $chip->read_config->get;
if( $PRINT_CONFIG ) {
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

my $max = $config->{atime_cycles} * 1024;
$max = 65535 if $max > 65535;

while(1) {
   my ( $c, $r, $g, $b );

   printf "Clear %5d RGB<%5d %5d %5d>\n",
      ( $c, $r, $g, $b ) = $chip->read_crgb->get;

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

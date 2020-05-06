#!/usr/bin/perl

use utf8;

use strict;
use warnings;

use Device::Chip::BNO055;
use Device::Chip::Adapter;

use Getopt::Long;
use Time::HiRes qw( sleep );

STDOUT->binmode( ":encoding(UTF-8)" );

GetOptions(
   'i|interval=i'   => \(my $INTERVAL = 0.1),
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \my $ADAPTER,
) or exit 1;

my $chip = Device::Chip::BNO055->new;
$chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
)->get;

$chip->protocol->power(0)->get;

$chip->protocol->power(1)->get;
END { $chip and $chip->protocol->power(0)->get }

print "Awaiting chip boot...\n";
sleep 1; # chip needs 650msec to boot

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

$chip->read_ids->get eq "A0FB320F" or
   die "Chip IDs do not match BNO055 signature\n";

if( $PRINT_CONFIG ) {
   my $config = $chip->read_config->get;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

$chip->set_opr_mode( "IMU" )->get;

while(1) {
   #printf "Accel <%+.2f %+.2f %+.2f> m/s²  ",
   #   $chip->read_accelerometer->get;

   #printf "Mag <% 6.2f % 6.2f % 6.2f> µT  ",
   #   $chip->read_magnetometer->get;

   #printf "Quart <%+.5f %+.5f %+.5f %+.5f>  ",
   #   $chip->read_quarternion->get;

   printf "Gyro <% 7.2f % 7.2f % 7.2f> °/s  ",
      $chip->read_gyroscope->get;

   printf "Linear <% .2f % .2f % .2f> m/s²  ",
      $chip->read_linear_acceleration->get;

   printf "Gravity <% .2f % .2f % .2f> m/s²  ",
      $chip->read_gravity->get;

   print "\n";

   sleep $INTERVAL;
}

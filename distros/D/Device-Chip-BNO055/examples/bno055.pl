#!/usr/bin/perl

use utf8;

use v5.26;
use warnings;

use Device::Chip::BNO055;
use Device::Chip::Adapter;

use Future::AsyncAwait;

use Getopt::Long;
use Time::HiRes qw( sleep );

STDOUT->binmode( ":encoding(UTF-8)" );

GetOptions(
   'i|interval=i'   => \(my $INTERVAL = 0.1),
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \my $ADAPTER,
) or exit 1;

my $chip = Device::Chip::BNO055->new;
await $chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

await $chip->protocol->power(0);

await $chip->protocol->power(1);
END { $chip and $chip->protocol->power(0)->get }

print "Awaiting chip boot...\n";
sleep 1; # chip needs 650msec to boot

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

( await $chip->read_ids ) eq "A0FB320F" or
   die "Chip IDs do not match BNO055 signature\n";

if( $PRINT_CONFIG ) {
   my $config = await $chip->read_config;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

await $chip->set_opr_mode( "IMU" );

while(1) {
   #printf "Accel <%+.2f %+.2f %+.2f> m/s²  ",
   #   await $chip->read_accelerometer;

   #printf "Mag <% 6.2f % 6.2f % 6.2f> µT  ",
   #   await $chip->read_magnetometer;

   #printf "Quart <%+.5f %+.5f %+.5f %+.5f>  ",
   #   await $chip->read_quarternion;

   printf "Gyro <% 7.2f % 7.2f % 7.2f> °/s  ",
      await $chip->read_gyroscope;

   printf "Linear <% .2f % .2f % .2f> m/s²  ",
      await $chip->read_linear_acceleration;

   printf "Gravity <% .2f % .2f % .2f> m/s²  ",
      await $chip->read_gravity;

   print "\n";

   sleep $INTERVAL;
}

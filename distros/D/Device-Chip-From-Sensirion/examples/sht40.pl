#!/usr/bin/perl

use v5.26;
use warnings;
use utf8;

use Device::Chip::SHT4x;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Future::IO;

use Getopt::Long qw( :config no_ignore_case );

STDOUT->binmode( ":encoding(UTF-8)" );

GetOptions(
   'i|interval=i'   => \(my $INTERVAL = 10),
   'p|print-config' => \my $PRINT_CONFIG,
   'addr|a=s'       => \my $ADDR,

   'adapter|A=s' => \my $ADAPTER,
) or exit 1;

my $chip = Device::Chip::SHT4x->new;
await $chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   addr => $ADDR,
);

await $chip->protocol->power(1);
await Future::IO->sleep( 0.05 ); # power-on delay

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   $chip and $chip->protocol->power(0)->get;
}

# Set any other config changes
if( @ARGV ) {
   my %changes;
   while( @ARGV ) {
      my ( $name, $value ) = ( shift @ARGV ) =~ m/^(.*?)=(.*)$/ or next;
      $changes{$name} = $value;
   }
   await $chip->change_config( %changes );
}

printf "Chip serial: %v02X\n", await $chip->get_serial_number;

if( $PRINT_CONFIG ) {
   my $config = await $chip->read_config;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

while(1) {
   await Future::IO->sleep( $INTERVAL );

   my ( $temp, $hum ) = await $chip->read_measurement
      or print( "(awaiting ready)\n" ), next;

   printf "Temperature=%.2fC  ", $temp;

   printf "Humidity=%.2f%%\n", $hum;
}

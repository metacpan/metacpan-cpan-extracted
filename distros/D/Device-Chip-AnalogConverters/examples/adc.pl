#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::Adapter;

use Getopt::Long;
use Time::HiRes qw( sleep );

GetOptions(
   'chip|C=s'    => \( my $CHIP ),
   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),

   'p|print-config' => \my $PRINT_CONFIG,
   'interval|i=f' => \( my $INTERVAL = 0.25 ),
   'ref|r=f'      => \( my $REFERENCE ),
) or exit 1;

$CHIP //= shift @ARGV;
defined $CHIP or die "Require --chip\n";

my $chip = do {
   my $chipclass = "Device::Chip::$CHIP";
   require ( "$chipclass.pm" =~ s{::}{/}gr );
   $chipclass->new;
};

$chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
)->get;

$chip->protocol->power(1)->get;
END { $chip->protocol->power(0)->get if $chip }

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

my $HAVE_TRIGGER          = $chip->can( 'trigger' );
my $HAVE_READ_ADC_VOLTAGE = $chip->can( 'read_adc_voltage' );
my $HAVE_READ_ADC_RATIO   = $chip->can( 'read_adc_ratio' );

if( @ARGV ) {
   my %changes = map { ( $_ =~ m/^(.*?)=(.*)/ ) } @ARGV;
   $chip->change_config( %changes )->get;

   sleep 0.1; # Allow chip to settle from any config changes
}

if( $chip->can( "init" ) ) {
   $chip->init->get;
}

if( $PRINT_CONFIG ) {
   my $config = $chip->read_config->get;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

while( 1 ) {
   $chip->trigger->get, sleep 0.05 if $HAVE_TRIGGER;

   if( $HAVE_READ_ADC_VOLTAGE ) {
      printf "ADC voltage %fV\n", $chip->read_adc_voltage->get;
   }
   elsif( $HAVE_READ_ADC_RATIO and defined $REFERENCE ) {
      printf "ADC voltage %fV\n", $chip->read_adc_ratio->get * $REFERENCE;
   }
   else {
      printf "ADC raw value: %X\n", $chip->read_adc->get;
   }

   sleep $INTERVAL;
}

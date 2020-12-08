#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::Adapter;

use Future::AsyncAwait;
use Getopt::Long;

GetOptions(
   'chip|C=s'    => \( my $CHIP ),
   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),

   'p|print-config' => \my $PRINT_CONFIG,
   'ref|r=f'      => \( my $REFERENCE ),
) or exit 1;

$CHIP //= shift @ARGV;
defined $CHIP or die "Require --chip\n";

my $chip = do {
   my $chipclass = "Device::Chip::$CHIP";
   require ( "$chipclass.pm" =~ s{::}{/}gr );
   $chipclass->new;
};

await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
);

await $chip->protocol->power(1);

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   #$chip and $chip->protocol->power(0)->get;
}

if( my @CHANGES = grep { m/.=./ } @ARGV ) {
   my %changes = map { ( $_ =~ m/^(.*?)=(.*)/ ) } @CHANGES;
   await $chip->change_config( %changes );

   @ARGV = grep { !m/.=./ } @ARGV;
}

if( $PRINT_CONFIG ) {
   my $config = await $chip->read_config;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

my ( $voltage, $dac );
if( $ARGV[0] =~ m/^(.*)V$/ ) {
   $voltage = $1;
   $voltage = $1 * 1E-3 if $voltage =~ m/^(.*)m$/;
   $voltage = $1 * 1E-6 if $voltage =~ m/^(.*)(?:u|µ)$/;
}
else {
   $dac = $ARGV[0] //
      die "Need voltage or DAC code\n";
}

if( $chip->can( "write_dac_voltage" ) and defined $voltage ) {
   await $chip->write_dac_voltage( $voltage );
}
elsif( defined $voltage ) {
   defined $REFERENCE or die "Need --reference for setting DAC ratio\n";
   await $chip->write_dac_ratio( $voltage / $REFERENCE );
}
else {
   await $chip->write_dac( $dac );
}

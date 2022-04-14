#!/usr/bin/perl

use v5.34;
use warnings;

use Future::AsyncAwait;
use Future::IO;

use Electronics::PSU::DPSxxxx;

my $psu = Electronics::PSU::DPSxxxx->new( dev => "/dev/ttyUSB0" );

printf "DPS%d, version %d\n", await $psu->read_model, await $psu->read_version;

printf "Supply voltage: %.2fV\n", await $psu->read_input_voltage;

await $psu->set_voltage( shift @ARGV or 10.22 );
await $psu->set_current( shift @ARGV or 0.456 );

await $psu->set_output_state( 1 );

$SIG{INT} = $SIG{TERM} = sub { exit };
END { $psu->set_output_state( 0 )->get; }

while(1) {
   printf "Output: %.2fV; %0.3fA %s\n",
      await $psu->read_multiple(qw( output_voltage output_current output_mode ));
}

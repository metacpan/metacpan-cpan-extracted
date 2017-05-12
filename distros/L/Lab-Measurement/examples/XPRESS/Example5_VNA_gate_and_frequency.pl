#!/usr/bin/env perl
use 5.020;

use warnings;
use strict;

use Lab::Measurement;

# Construct instruments.
my $vna = Instrument(
    'RS_ZVA', {
        connection_type => 'LinuxGPIB',
        gpib_address    => 20,
    }
);

my $source = Instrument(
    'YokogawaGS200', {
        connection_type => 'LinuxGPIB',
        gpib_address    => 2,
    }
);

# Define the 'outer' gate sweep.
my $sweep = Sweep(
    'Voltage',
    {
        instrument => $source,
        mode       => 'step',
        jump       => 1,
        points     => [ 0, 1 ],
        stepwidth  => [0.002],
        rate       => [0.1]
    }
);

my $DataFile = DataFile('vna-sweep');

# If we just measure one S-parameter, we will have 4 columns.
$DataFile->add_column('source_voltage');
$DataFile->add_column('freq');

# Get names of the configured S-parameter real/imag parts.
my @sparams = @{ $vna->sparam_catalog() };

for my $sparam (@sparams) {
    $DataFile->add_column($sparam);
}

my $measurement = sub {
    my $sweep   = shift;
    my $voltage = $sweep->get_value();
    my $data    = $vna->sparam_sweep();

    $sweep->LogBlock(
        prefix => [$voltage],
        block  => $data->matrix(),
    );
};

$DataFile->add_measurement($measurement);
$sweep->add_DataFile($DataFile);

$sweep->start();


#!/usr/bin/env perl
use warnings;
use strict;
use 5.010;

#-------- 0. Import Lab::Measurement -------

use Lab::Measurement;

#-------- 1. Initialize Instruments --------

my $ls = Instrument(
    'Lakeshore340', {
        connection_type => 'VISA_GPIB',
        gpib_address    => 19,
    }
);

#-------- 2. Define the Sweeps -------------

my $temperature_sweep = Sweep(
    'Temperature',
    {
        mode       => 'step',
        instrument => $ls,
        points     => [ 6, 10 ],    # [starting point, target] in K
        stepwidth  => 1,            # step width in K

        # absolute tolerance (in Kelvin) for temperature before waiting time
        tolerance_setpoint => 0.01,

        # allowed standard deviation (in Kelvin) for same
        std_dev_instrument => 0.01,

        # time that temperature has to be stable
        stabilize_observation_time => 30,

        # additional waiting time for sample to thermalize with mc
        #delay_in_loop => 10,

        # temperature read out period
        #stabilize_measurement_interval => 10,

        setter_args => [ { loop    => 1 } ],
        getter_args => [ { channel => 'C' } ],
    }
);

#-------- 3. Create a DataFile -------------

my $DataFile = DataFile('tempcurve.dat');

$DataFile->add_column('Temperature');
$DataFile->add_column('Data');

#-------- 4. Measurement Instructions -------

my $my_measurement = sub {

    my $sweep = shift;

    my $temperature = $ls->get_value( { channel => 'C' } );

    $sweep->LOG(
        {
            Temperature => $temperature,
            Data        => 0
        }
    );
};

#-------- 5. Put everything together -------

$DataFile->add_measurement($my_measurement);

$temperature_sweep->add_DataFile($DataFile);

$temperature_sweep->start();

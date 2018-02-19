#!/usr/bin/env perl
use Lab::Moose;

my $inst1 = instrument( type => 'DummySource', connection_type => 'Debug' );
my $inst1 = instrument( type => 'DummySource', connection_type => 'Debug' );
my $multimeter = instrument(...);

my $gate_sweep = sweep(
    type       => 'Voltage',
    instrument => $inst1,
    from       => 1,
    to         => 2,
    step       => 0.1
);

my $bias_sweep = sweep(
    type       => 'Voltage',
    instrument => $inst2,
    from       => -1,
    to         => 1,
    step       => 0.01
);

my $datafile = sweep_datafile(
    type    => 'Gnuplot2D',
    columns => [qw/gate bias current/],
);

my $meas = sub {
    my $sweep = shift;

    my $current = $multimeter->get_value();
    $sweep->log(
        gate    => $inst1->get_value(),
        bias    => $inst2->get_value(),
        current => $current,
    );
    }

    $gate_sweep->start(
    slave       => $bias_sweep,
    datafile    => $datafile,
    measurement => $meas
    );

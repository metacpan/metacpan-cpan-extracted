#!/usr/bin/perl
#PODNAME: coulomb-diamonds.pl
#ABSTRACT: Measure a quantum dot stability diagram, i.e. current versus gate and bias

use Lab::Moose;
use 5.010;


# sample description
my $sample  = 'mychip_';   # chip name
my $PINsI   = 'Vsd#2#3_';  # pin / cable numbers
my $PINGate = 'Vg#6_';

# parameters of the setup
my $lineresistance=4000;   # resistance of measurement line (Ohm)

# parameters of the measurement

my $biasstart = -0.5;    # start value of bias sweep in VOLTS
my $biasend = 0.5;       # end value of bias sweep in VOLTS
my $stepwidthVb = 0.002; # stepwidth of the biasyoko in VOLTS

my $gatestart = 0;       # start value of gate sweep in VOLTS
my $gateend = 1;         # end value of gate sweep in VOLTS
my $stepwidthVg = 0.004; # stepwidth of the gateyoko in VOLTS

my $sensitivity = -1e-10;# sensitivity of DL1211 in A/V, sign comes from device
my $risetime = 30;       # rise time in ms

my $divider = 1000;      # voltage divider between biasyoko and sample

my $NPLC = 1;            # DMM integration time in 1/50 sec


# instruments

my $multimeter = instrument(
    type => 'Keysight34470A',
    connection_type => 'VXI11',
    connection_options => {host => '192.168.3.28'},
);

my $biasyoko = instrument(
    type => 'YokogawaGS200',
    connection_type => 'LinuxGPIB',
    connection_options => {pad => 2},
    max_units_per_step => 0.05,
    max_units_per_second => 1,
    min_units => -10,
    max_units => 10,
);

my $gateyoko = instrument(
    type => 'YokogawaGS200',
    connection_type => 'LinuxGPIB',
    connection_options => {pad => 1},
    max_units_per_step => 0.001,
    max_units_per_second => 0.1,
    min_units => -10,
    max_units => 10,
);
 
# Sweeps

my $gate_sweep = sweep(
    type       => 'Step::Voltage',
    instrument => $gateyoko,
    from => $gatestart, to => $gateend, step => $stepwidthVg
);
 
my $bias_sweep = sweep(
    type       => 'Step::Voltage',
    instrument => $biasyoko,
    from => $biasstart, to => $biasend, step => $stepwidthVb
);

# Data file

my $datafile = sweep_datafile(columns => [qw/gate bias current/]);
$datafile->add_plot(
    type    => 'pm3d',
    x       => 'gate',
    y       => 'bias',
    z       => 'current'
);

# Measurement

my $meas = sub {
    my $sweep = shift;
    my $current = ($multimeter->get_value()*($sensitivity));
    my $v_b = (($biasyoko->cached_level())/($divider)); 
    $sweep->log(
        gate    => $gateyoko->cached_level(),
        bias    => $v_b,
        current => $current,
    );
};

# Run it all

$gate_sweep->start(
    slave       => $bias_sweep,
    measurement => $meas,
    datafile    => $datafile,
    folder      => $sample.$PINsI.$PINGate.'diamonds',
    date_prefix => 1,
);

__END__

=pod

=encoding UTF-8

=head1 NAME

coulomb-diamonds.pl - Measure a quantum dot stability diagram, i.e. current versus gate and bias

=head1 VERSION

version 3.682

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

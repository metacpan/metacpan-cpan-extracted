#!/usr/bin/env perl
#PODNAME: manual-T-IV-freq.pl
#ABSTRACT: Complex example of custom sweep without Sweep framework

use lib '/home/simon/lab-measurement/lib';

use Lab::Moose;               # get instrument, datafolder, datafile, linspace
use Lab::Moose::Countdown;    # get countdown
use Lab::Moose::Stabilizer;   # get stabilize
my $voltage_source = instrument(
    type               => 'DummySource',
    connection_type    => 'Debug',
    connection_options => { verbose => 0 },

    # Safety limits:
    max_units          => 10,   min_units            => -10,
    max_units_per_step => 0.11, max_units_per_second => 10
);

my $freq_source = instrument(
    type => 'RS_SMB',
    ...
);

my $oi_triton = instrument(
    type               => 'OI_Triton',
    connection_type    => 'Socket',
    connection_options => { host => 'triton' },
);

my $folder = datafolder();

my $IV_datafile = datafile(
    folder  => $folder, filename => 'data_IV.dat',
    columns => [qw/temp voltage current/]
);

$IV_datafile->add_plot(
    x      => 'voltage',
    y      => 'current',
    legend => 'temp',
);

my $freq_datafile = datafile(
    folder  => $folder, filename => 'data_freq.dat',
    columns => [qw/temp freq current/]
);

$freq_datafile->add_plot(
    x      => 'freq',
    y      => 'current',
    legend => 'temp'
);

my @temperatures = linspace( from => 20e-3, to => 500e-3, step => 20e-3 );
my @voltages     = linspace( from => 0,     to => 1,      step => 0.1 );
my @frequencies = linspace( from => 1e3 to => 50e3, step => 1e3 );

for my $temp (@temperatures) {
    $oi_triton->set_T( value => $temp );
    stabilize(
        instrument           => $oi_triton,
        setpoint             => $temp,
        getter               => 'get_T',
        tolerance_setpoint   => 1e-3,
        tolerance_std_dev    => 1e-3,
        measurement_interval => 60,
        observation_time     => 5 * 60,
        verbose              => 1,
    );

    # IV sweep

    # Go to sweep start
    $voltage_source->set_level( value => $voltages[0] );
    countdown(5);

    for my $voltage (@voltages) {
        $voltage_source->set_level( value => $voltage );
        $IV_datafile->log(
            temp    => $temp,
            voltage => $voltage,
            current => ...
        );
    }

    $voltage_source->set_level( value => 0 );

    $IV_datafile->new_block();

    # Freq sweep
    # Go to sweep start
    $freq_source->set_freq( value => $frequencies[0] );
    countdown(5);

    for my $freq (@frequencies) {
        $freq_source->set_freq( value => $freq );
        $freq_datafile->log(
            temp    => $temp,
            freq    => $freq,
            current => ...
        );
    }
    $freq_datafile->new_block();

    );

__END__

=pod

=encoding UTF-8

=head1 NAME

manual-T-IV-freq.pl - Complex example of custom sweep without Sweep framework

=head1 VERSION

version 3.823

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by the Lab::Measurement team; in detail:

  Copyright 2019       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

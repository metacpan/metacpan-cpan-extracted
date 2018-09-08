#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

use lib 'lib';

use Lab::Moose;

use File::Temp 'tempfile';

my ( undef, $filename ) = tempfile();

sub dummysource {
    return instrument(
        type                 => 'DummySource',
        connection_type      => 'Debug',
        connection_options   => { verbose => 0 },
        verbose              => 0,
        max_units            => 10,
        min_units            => -10,
        max_units_per_step   => 100,
        max_units_per_second => 1000000,
    );
}

my $gate_source = dummysource();
my $bias_source = dummysource();

warn "output folder: $filename";

my $gate_sweep = sweep(
    type => 'Step::Voltage', instrument => $gate_source,
    list      => [ 1, 2, 3, 4 ],
    backsweep => 1,
);

my $bias_sweep = sweep(
    type       => 'Step::Voltage',
    instrument => $bias_source,
    from       => -1,
    to         => 1,
    step       => 0.01,
);

my $datafile = sweep_datafile( columns => [qw/gate bias current/] );
my $curve_options = { with => 'lines', linewidth => 2 };

$datafile->add_plot(
    x             => 'bias',
    y             => 'current',
    curve_options => { linetype => 1 },

    #legend => 'gate',
    #    plot_options => {key => [qw/left top/]},
);

my $drift = 0;
my $meas  = sub {
    my $sweep   = shift;
    my $gate    = $gate_source->cached_level();
    my $bias    = $bias_source->cached_level();
    my $current = $bias * $gate + $drift;
    $drift += 0.001;
    $sweep->log( gate => $gate, bias => $bias, current => $current );
};

$gate_sweep->start(
    slave       => $bias_sweep,
    datafiles   => [$datafile],
    measurement => $meas,
    folder      => $filename,

);


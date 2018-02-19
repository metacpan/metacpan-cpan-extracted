#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

use lib 'lib';

use Lab::Moose;

use File::Temp 'tempfile';

my ( undef, $filename ) = tempfile();
warn "output folder: $filename\n";

sub dummysource {
    return instrument(
        type                 => 'DummySource',
        connection_type      => 'Debug',
        connection_options   => { verbose => 0 },
        verbose              => 0,
        max_units            => 1000000,
        min_units            => -10,
        max_units_per_step   => 100,
        max_units_per_second => 1000000,
    );
}

my $gate = dummysource();
my $bias = dummysource();

my $size   = 100;
my $center = $size / 2;

my $gate_sweep = sweep(
    type => 'Step::Voltage', instrument => $gate, from => 0,
    to   => 10,              step       => 1
);
my $bias_sweep = sweep(
    type => 'Step::Voltage', instrument => $bias, from => 0,
    to   => 10000,           step       => 1
);

my $datafile_3d = sweep_datafile( columns => [qw/gate bias current/] );
$datafile_3d->add_plot(
    type => 'pm3d', x => 'gate', y => 'bias',
    z    => 'current'
);

my $meas = sub {
    my $sweep = shift;
    my $x     = $gate->cached_level();
    my $y     = $bias->cached_level();
    $sweep->log( gate => $x, bias => $y, current =>
            sin( sqrt( ( $x - $center )**2 + ( $y - $center )**2 ) / 10 ) );
};

$gate_sweep->start(
    slaves      => [$bias_sweep],
    datafiles   => [$datafile_3d],
    measurement => $meas,
    folder      => $filename,
);

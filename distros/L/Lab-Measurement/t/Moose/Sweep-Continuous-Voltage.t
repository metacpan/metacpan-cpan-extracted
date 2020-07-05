#!perl

use warnings;
use strict;
use 5.010;
use lib 't';
use Test::More;
use Lab::Test import => [qw/is_absolute_error/];
use File::Spec::Functions 'catfile';
use Lab::Moose::DataFile::Read;
use Lab::Moose;
use Time::HiRes 'time';
use File::Temp qw/tempdir/;
use Data::Dumper;

my $dir = catfile( tempdir(), 'sweep' );

my $source = instrument(
    type                 => 'DummySource',
    connection_type      => 'Debug',
    connection_options   => { verbose => 0 },
    verbose              => 0,
    max_units            => 100,
    min_units            => -10,
    max_units_per_step   => 100,
    max_units_per_second => 1000000,
);

my @intervals = ( 1, 2 );
my @points = ( 0, 10.5, 0 );
my @rates = (
    2,    # sweep start rate
    2,    # rate for 0 -> 10.5
    5
);        # rate for 10.5 -> 0

my $sweep = sweep(
    type       => 'Continuous::Voltage',
    instrument => $source,
    points     => [@points],
    rates      => [@rates],
    intervals  => [@intervals],
);

my $datafile     = sweep_datafile( columns => [qw/voltage/] );
my $index        = 0;
my $timing_error = 0.5;

my $meas = sub {
    my $sweep = shift;
    my $v     = $source->get_level();
    if ( $index < 6 ) {
        is_absolute_error(
            $v,                        $index * $rates[1] * $intervals[0],
            $rates[1] * $timing_error, "voltage is $v"
        );
    }
    if ( $index == 6 || $index == 7 ) {
        is_absolute_error(
            $v, $points[1], $rates[2] * $timing_error,
            "voltage is $v"
        );
    }
    if ( $index == 8 ) {
        is_absolute_error(
            $v, 0.5, $rates[2] * $timing_error,
            "voltage is $v"
        );
    }
    if ( $index == 9 ) {
        is( $v, $points[-1], "voltage back at 0" );
    }
    $sweep->log( voltage => $v );
    ++$index;
};

$sweep->start(
    measurement => $meas,
    datafile    => $datafile,
    folder      => $dir,

    # use default datafile_dim and point_dim
);

done_testing();

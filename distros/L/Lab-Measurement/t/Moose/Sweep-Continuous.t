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

{
    #
    # Time sweep
    #
    my @intervals = ( 0.1, 0.2 );
    my @durations = ( 0.5, 0.6 );

    my $num_points0 = $durations[0] / $intervals[0] + 1;
    my $num_points1 = $durations[1] / $intervals[1] + 1;
    my $sweep       = sweep(
        type      => 'Continuous::Time',
        durations => [@durations],
        intervals => [@intervals],
    );

    my $datafile = sweep_datafile( columns => [qw/time value/] );

    my $value = 0;
    my $t0;

    my $meas = sub {
        my $sweep = shift;
        $sweep->log( time => time() - $t0, value => $value++ );
    };

    $t0 = time();
    $sweep->start(
        measurement => $meas,
        datafile    => $datafile,
        folder      => $dir,

        # use default datafile_dim and point_dim
    );
    my $path = catfile( $sweep->foldername, 'data.dat' );

    my @cols = read_gnuplot_format(
        type => 'columns', file => $path,
        num_columns => 2

    );
    my $times = $cols[0]->unpdl();
    print Dumper $times;
    is( @{$times}, $num_points0 + $num_points1, "datafile size" );

    is_absolute_error(
        $times->[ $num_points0 - 1 ],
        $times->[0] + $durations[0], $intervals[0],
        "first sweep segment look ok"
    );

    is_absolute_error(
        $times->[-1],  $times->[$num_points0] + $durations[1],
        $intervals[1], "second sweep segment look ok"
    );
}

warn "dir: $dir\n";

done_testing();

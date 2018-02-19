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
    my $interval = 0.02;
    my $duration = 0.1;
    my $sweep    = sweep(
        type     => 'Continuous::Time',
        duration => $duration,
        interval => $interval,
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
    warn "start_time: ", $sweep->start_time - $t0;
    my $path = catfile( $sweep->foldername, 'data.dat' );

    my @cols = read_gnuplot_format(
        type => 'columns', file => $path,
        num_columns => 2

    );
    my $times = $cols[0]->unpdl();
    print Dumper $times;

    is( @{$times}, 6, "datafile size" );

    is_absolute_error(
        $times->[-1], $times->[0] + $duration, $interval,
        "duration is withing error bounds"
    );
}

warn "dir: $dir\n";

done_testing();

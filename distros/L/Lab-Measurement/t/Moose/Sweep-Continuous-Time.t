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

#
# Time sweep
#

my $sweep = sweep(
    type     => 'Continuous::Time',
    duration => 4.5,
    interval => 1,
);

my $datafile = sweep_datafile( columns => [qw/time/] );

my $index = 0;
my $t0;
my $timing_error = 0.5;
my $meas         = sub {
    my $sweep = shift;
    my $t     = time() - $t0;
    is_absolute_error( $t, $index, $timing_error, "time is $t" );
    $sweep->log( time => $t );
    ++$index;
};

$t0 = time();
$sweep->start(
    measurement => $meas,
    datafile    => $datafile,
    folder      => $dir,

    # use default datafile_dim and point_dim
);

is( $index, 6, "index is 4" );

done_testing();

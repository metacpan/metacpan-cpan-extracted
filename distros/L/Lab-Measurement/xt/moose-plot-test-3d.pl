#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

use lib 'lib';

use Lab::Moose;

use File::Temp 'tempfile';

my ( undef, $filename ) = tempfile();
warn "output folder: $filename\n";

my $datafile_3d = datafile(
    type     => 'Gnuplot',
    folder   => datafolder( path => $filename ),
    filename => 'data.dat',
    columns  => [qw/x y z/],
);

$datafile_3d->add_plot(
    type => 'pm3d',
    x    => 'x',
    y    => 'y',
    z    => 'z',
);

my $size   = 100;
my $center = $size / 2;

for my $x ( 0 .. $size ) {
    for my $y ( 0 .. $size ) {
        $datafile_3d->log(
            x => $x,
            y => $y,
            z => sin( sqrt( ( $x - $center )**2 + ( $y - $center )**2 ) / 10 )
        );
    }
    $datafile_3d->new_block();
}

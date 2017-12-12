#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

use lib 'lib';

use Lab::Moose;

use File::Temp 'tempfile';

my ( undef, $filename ) = tempfile();
warn "output folder: $filename";
my $datafile_2d = datafile(
    type     => 'Gnuplot',
    folder   => datafolder( path => $filename ),
    filename => 'file.dat',
    columns  => [qw/x y/],
);

$datafile_2d->add_plot(
    x         => 'x',
    y         => 'y',
    hard_copy => 'file.png',
);

for my $x ( 1 .. 100 ) {
    $datafile_2d->log( x => $x, y => $x**2 );
}


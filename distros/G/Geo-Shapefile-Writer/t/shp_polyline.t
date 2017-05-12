#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp;

use Geo::Shapefile::Writer;

my $dir = File::Temp->newdir();
my $dirname = $dir->dirname();

my $name = 'lines';

my $s = Geo::Shapefile::Writer->new(
    "$dirname/$name", 'POLYLINE',
    'name'
);

$s->add_shape( [[[0,0],[1,1],[2,1]]], 'line' );
$s->add_shape( [[[0,0],[1,0]],[[1,1],[1,0]]], 'multi-line' );
$s->finalize();

for my $ext ( qw/ shp shx dbf / ) {
    ok( (-s "$dirname/$name.$ext"), lc($ext) . " created" );
}

done_testing();




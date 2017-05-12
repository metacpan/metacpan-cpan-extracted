#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;

use File::Temp;

use Geo::Shapefile::Writer;

my $dir = File::Temp->newdir();
my $dirname = $dir->dirname();

my $name = 'summits';

dies_ok { Geo::Shapefile::Writer->new("$dirname/$name", 'POINTTT', 'name') }
    'bad type';
dies_ok { Geo::Shapefile::Writer->new("$dirname/$name", 'POINT', []) }
    'bad format';

my $s = Geo::Shapefile::Writer->new(
    "$dirname/$name", 'POINT',
    'name',
    [ elevation => 'N', 8, 0 ],
    { name => 'comment', type => 'C', length => '200' },
);

$s->add_shape( [86.925278, 27.988056], 'Everest', 8848, 'highest!' );
$s->add_shape( [42.436944, 43.353056], { name => 'Elbrus', elevation => 5642 } );
$s->finalize();

for my $ext ( qw/ shp shx dbf / ) {
    ok( (-s "$dirname/$name.$ext"), lc($ext) . " created" );
}

done_testing();




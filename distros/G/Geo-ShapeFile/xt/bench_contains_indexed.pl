#!/usr/bin/perl -w
use strict;
use warnings;
use English qw / -no_match_vars /;

use 5.010;

use rlib '../lib', '../t/lib';

local $| = 1;

use Geo::ShapeFile;
use Geo::ShapeFile::Shape;

use Benchmark qw /:all/;

use FindBin;


my $reps      = $ARGV[0] // -5;
my $index_res = $ARGV[1] // 10;
my $prebuild  = $ARGV[2] // 0;


my $dir = "$FindBin::Bin/../t/test_data";
my $base = "polygon";
#$base = "states";
my $file = "$dir/$base";



#  no index per shape - we can still index the shapes themselves
my $shp_no_index = Geo::ShapeFile->new ($file);
$shp_no_index->build_spatial_index;

my $shp_use_index = Geo::ShapeFile->new ($file);
$shp_use_index->build_spatial_index;

#  Generate a set of random points across the bounds
#  Not truly ranodom, but random enough.
my @bounds  = $shp_no_index->bounds;
my $x_min   = $bounds[0];
my $y_min   = $bounds[1];
my $x_range = $bounds[2] - $x_min;
my $y_range = $bounds[3] - $y_min;

my $n = 100;

my (@points, %point_hash);

foreach my $i (1 .. $n) {
    my $x = $x_min + rand($x_range);
    my $y = $y_min + rand($y_range);
    my $pt = Geo::ShapeFile::Point->new(X => $x, Y => $y);
    push @points, $pt;
    $point_hash{"$pt"} = $pt;
}

my $sp_index1 = $shp_no_index->get_spatial_index;
my $sp_index2 = $shp_use_index->get_spatial_index;

#  reduce the search space a bit
my (%shape_set1, %shape_set2);

POINT:
foreach my $pt (@points) {
    my @point = ($pt->get_x, $pt->get_y);

    my @shapes1;
    $sp_index1->query_point(@point, \@shapes1);
    
    next POINT if !@shapes1;  #  skip if none there
    
    $shape_set1{"$pt"} = \@shapes1;

    my @shapes2;
    $sp_index2->query_point(@point, \@shapes2);
    $shape_set2{"$pt"} = \@shapes2;
}

#  prebuild the indexes
if ($prebuild) {
    say 'prebuilding shape indexes';
    foreach my $shape ($shp_use_index->get_all_shapes) {
        $shape->build_spatial_index ($index_res);
    }
}

say 'Working with ', scalar (keys %shape_set1), ' points';

#  now we finally get to the benchmark
cmpthese (
    $reps,
    {
        use_index => sub {use_index()},
        no_index  => sub {no_index()},
    }
);


sub no_index {
    my $use_index = undef;

    foreach my $pt_id (keys %shape_set1) {
        my $pt = $point_hash{$pt_id};
        my $shapes = $shape_set1{$pt_id};
        foreach my $shp (@$shapes) {
            my $result = $shp->contains_point ($pt, $use_index);
        }
    }
    
}

sub use_index {
    my $use_index = $index_res;

    foreach my $pt_id (keys %shape_set2) {
        my $pt = $point_hash{$pt_id};
        my $shapes = $shape_set2{$pt_id};
        foreach my $shp (@$shapes) {
            my $result = $shp->contains_point ($pt, $use_index);
        }
    }
}


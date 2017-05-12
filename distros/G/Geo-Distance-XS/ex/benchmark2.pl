#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark qw(cmpthese timethese);
use Geo::Distance::XS;
use List::Util qw(max);

my @tests = (
    'short distance',
    'long distance',
    'nearly antipodes',
    'antipodes',
    'polar antipodes',
);
my @coords = (
    [ -118.6414,   34.3502,   -117.9739,  34.1607 ],
    [ -118.243103, 34.159545, -73.987427, 40.853293 ],
    [ 0.,          0.,        -179.,      1. ],
    [ 175.,        12.,       -5.,        -12. ],
    [ 0.,          90.,       0.,         -90. ],
);

my %geos;
my @formulas = @Geo::Distance::XS::FORMULAS;
my $max_name_len = 0;
for my $f (@formulas) {
    my $geo = Geo::Distance->new;
    $geo->formula($f);
    $geos{$f} = sub { $geo->distance(mile => @$_) for @coords };
    $max_name_len = max $max_name_len, length($f);
}

cmpthese - 1, \%geos;

print "\n";
for my $idx (0 .. $#tests) {
    print "Calculated length for $tests[$idx]:\n";
    for my $f (@formulas) {
        my $geo = Geo::Distance->new;
        $geo->formula($f);
        my $d = $geo->distance(mile => @{$coords[$idx]});
        printf "    %-*s: %s miles\n", $max_name_len, $f, $d;
    }
    print "\n";
}

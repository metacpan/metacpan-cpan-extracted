#!/usr/bin/env perl
use 5.008001;
use strictures 2;
use Test2::V0;

use GIS::Distance;

my $test_cases = {
    'Canoga Park to San Francisco' => [ 34.202361, -118.601875,  37.752258, -122.441254,   524.347542197146, 'km'],
    'Egypt to Anchorage'           => [ 26.185018,   30.047607,  61.147543, -149.81575,  10324.656666156,    'km'],
    'London to Sydney'             => [ 51.497736,   -0.115356, -33.81966,   151.169472, 16982.5402359324,   'km'],
    'Santiago to Rio de Janeiro'   => [-33.446339,  -70.63591,  -22.902981,  -43.213177,  2923.66733201558,  'km'],
    'Beirut to Dimashq'            => [ 33.863146,   35.52824,   33.516496,   36.287842, 80241.1054436632,   'm' ],
};
my $test_case_count = @{[ keys %$test_cases ]} + 0;

test_formula( 'GeoEllipsoid' );

done_testing;

sub test_formula {
    my ($formula) = @_;
    my $gis = GIS::Distance->new( "GIS::Distance::$formula" );
    foreach my $title (keys %$test_cases) {
        my $case     = $test_cases->{$title};
        my $unit     = $case->[5];
        my $distance = $case->[4];

        my $length = $gis->distance( $case->[0], $case->[1], $case->[2], $case->[3] )->$unit();

        is_close( $length, $distance, $title );
    }
}

sub is_close {
    my ($num1, $num2, $description) = @_;
    my $lossy = $num2 * 0.00189;
    if (($num1 > $num2 + $lossy) or ($num1 < $num2 - $lossy)) {
        fail( "$description - $num1 != $num2" );
    }
    else {
        pass( "$description - $num1 =~ $num2" );
    }
}


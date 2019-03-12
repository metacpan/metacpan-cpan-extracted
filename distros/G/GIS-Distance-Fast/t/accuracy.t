#!/usr/bin/env perl
use 5.008001;
use strictures 2;
use Test2::V0;

use GIS::Distance;

my @coords = ( 34.202361, -118.601875,  37.752258, -122.441254 );
my @formulas = qw( ALT Cosine GreatCircle Haversine Polar Vincenty );
my $gis = GIS::Distance->new();

foreach my $formula (@formulas) {
    my $s_gis = GIS::Distance->new( "GIS::Distance::$formula" );
    my $s_length = $gis->distance( @coords )->km();

    my $f_gis = GIS::Distance->new( "GIS::Distance::Fast::$formula" );
    my $f_length = $gis->distance( @coords )->km();

    is_close( $s_length, $f_length, $formula );
}

done_testing;

sub is_close {
    my ($num1, $num2, $description) = @_;
    my $lossy = $num2 * 0.001;
    if (($num1 > $num2 + $lossy) or ($num1 < $num2 - $lossy)) {
        fail( "$description - $num1 != $num2" );
    }
    else {
        pass( "$description - $num1 =~ $num2" );
    }
}

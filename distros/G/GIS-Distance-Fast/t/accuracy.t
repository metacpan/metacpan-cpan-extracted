#!/usr/bin/env perl
use strictures 1;

use Test::More;

use_ok( 'GIS::Distance' );

my @coords = ( 34.202361, -118.601875,  37.752258, -122.441254 );
my @formulas = qw( Haversine Cosine Vincenty );
my $gis = GIS::Distance->new();

foreach my $formula (@formulas) {
    $gis->formula( 'GIS::Distance::Formula::'.$formula );
    my $s_length = $gis->distance( @coords )->km();

    $gis->formula( 'GIS::Distance::Formula::'.$formula.'::Fast' );
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


#!/usr/bin/end perl
use 5.008001;
use strictures 2;
use Test2::V0;

use GIS::Distance;

my @coords = ( -84.302183, 58.886719, -81.24166, -154.951172 );

my $vincenty = GIS::Distance->new( 'GIS::Distance::Vincenty' );
my $polar = GIS::Distance->new( 'GIS::Distance::Polar' );

my $v_length = $vincenty->distance( @coords );
my $p_length = $polar->distance( @coords );

todo 'Polar formula is broken' => sub{
    is_close( $v_length->km(), $p_length->km(), 'Vincenty versus Polar' );
};

sub is_close {
    my ($num1, $num2, $description) = @_;
    my $lossy = $num2 * 0.01;
    if (($num1 > $num2 + $lossy) or ($num1 < $num2 - $lossy)) {
        fail( "$description - $num1 != $num2" );
    }
    else {
        pass( "$description - $num1 =~ $num2" );
    }
}

done_testing;

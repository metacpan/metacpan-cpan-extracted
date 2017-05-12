package Geo::Mercator;

use Math::Trig qw(tan atan pi);
use base qw(Exporter);

our @EXPORT = qw(mercate demercate);

use strict;
use warnings;

our $VERSION ='1.01';

our $DEG_TO_RAD = (pi/180.0);
our $RAD_TO_DEG = (180.0/pi);
our $R_MAJOR = 6378137.000;
our $R_MINOR = 6356752.3142;
our $PI_OVER_2 = (pi/2);
our $ECCENT = sqrt(1.0 - ($R_MINOR / $R_MAJOR) * ($R_MINOR / $R_MAJOR));
our $ECCENTH = (0.5 * $ECCENT);

sub mercate {
    return ($R_MAJOR * $DEG_TO_RAD * $_[1], _mercate_lat($_[0])); 
}

sub _mercate_lat {
#
#	limit the polar damage
#
    my $phi = $DEG_TO_RAD * (
    	  ($_[0] > 89.5) ? 89.5
		: ($_[0] < -89.5) ?-89.5
		: $_[0]);
    my $sinphi = sin($phi);
    my $con = $ECCENT * $sinphi;
    $con = ((1.0 - $con)/(1.0 + $con)) ** $ECCENTH;
    my $ts = tan(0.5 * ($PI_OVER_2 - $phi))/$con;
    return 0 - $R_MAJOR * log($ts);
}

sub demercate {
    return ( _demercate_y($_[1]), $RAD_TO_DEG * $_[0] / $R_MAJOR);
}
#
#	!!!WE NEED A MORE ACCURATE SOLUTION TO THIS!!!
#
sub _demercate_y {
    my $ts = exp(- $_[0] / $R_MAJOR);
    my $phi = $PI_OVER_2 - 2 * atan($ts);
    my $i = 0;
    my $dphi = 1;
    while(abs($dphi) > 0.000000001 && $i < 15) {
      my $con = $ECCENT * sin($phi);
      $dphi = $PI_OVER_2 - 2.0 * atan($ts * (((1.0 - $con) / (1.0 + $con))**$ECCENTH)) - $phi;
      $phi += $dphi;
      $i++;
    } 
    return $RAD_TO_DEG * $phi; 
}

1;

package GIS::Distance::Lite;

use strict;
use Math::Trig;
use Exporter 'import';

our @EXPORT_OK = qw(distance);
our $VERSION = "1.0";

=head1 NAME

GIS::Distance::Lite - Calculate geographic distances between coordinates in geodetic WGS84 format.	

=head1 SYNOPSIS

  use GIS::Distance::Lite qw(distance);
    
  my $distanceInMeters = distance($lat1, $lon1 => $lat2, $lon2);


=head1 DESCRIPTION

The module provides a method to calculate geographic distances between coordinates in geodetic WGS84 format using the Haversine formula.

It is similar to L<GIS::Distance>, but without the extra bells and whistles and without the additional dependencies. Same great taste, less filling.
It exists for those who cannot, or prefer not to install Moose and its dependencies.


=over 2

=item  my $distanceInMeters = GIS::Distance::Lite::distance($lat1, $lon1 => $lat2, $lon2);

Calculate distance between two set of coordinates.

Parameters:

 $latitude1  (number)
 $longitude1 (number)
 $latitude2  (number)
 $longitude2 (number)


Example:

 my $distanceInMeters = GIS::Distance::Lite::distance(59.26978, 18.03948 => 59.27200, 18.05375);

Returns:

the distance in meters;

=cut

sub distance {
    my ($lat1, $lon1, $lat2, $lon2) = @_;
    $lon1 = deg2rad($lon1);
    $lat1 = deg2rad($lat1);
    $lon2 = deg2rad($lon2);
    $lat2 = deg2rad($lat2);

    my $dlon = $lon2 - $lon1;
    my $dlat = $lat2 - $lat1;
    my $a = (sin($dlat/2)) ** 2 + cos($lat1) * cos($lat2) * (sin($dlon/2)) ** 2;
    my $c = 2 * atan2(sqrt($a), sqrt(1-$a));

    return 6371640 * $c
}

1;

=head1 SEE ALSO

Inspired by: L<GIS::Distance>

Haversine formula: http://en.wikipedia.org/wiki/Haversine_formula

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHORS

Author: Johan Beronius <johanb@athega.se>, 2010. http://www.athega.se/

=cut

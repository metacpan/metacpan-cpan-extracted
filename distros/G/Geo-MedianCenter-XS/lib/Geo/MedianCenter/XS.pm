package Geo::MedianCenter::XS;

use 5.008000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  &haversine_distance_rad
  &haversine_distance_dec
  &median_center
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  &median_center
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Geo::MedianCenter::XS', $VERSION);

1;

__END__

=head1 NAME

Geo::MedianCenter::XS - Find the median center of locations on earth

=head1 SYNOPSIS

  use Geo::MedianCenter::XS qw/haversine_distance_dec median_center/;

  my $distance = haversine_distance_dec(
    54.728569, 8.7057573, # Dagebuell-Hafen
    54.730320, 8.7289753, # Dagebuell-Kirche
  );

  my ($center_lat, $center_lon) = median_center({
    points => [
      [ 54.728569, 8.7057573 ], # Dagebuell-Hafen
      [ 54.730320, 8.7289753 ], # Dagebuell-Kirche
      [ 54.639998, 8.6017305 ], # Langeness
      [ 54.492014, 8.8648961 ], # Nordstrand
    ],
  });

=head1 DESCRIPTION

This module finds the geometric median point of locations on the earth's
surface. Also known as euclidean space this is the point where the sum
of great circle distances to the locations is minimal. The point is more
resistant to outliers than the mean center. The module will guess a point
and refine it based on the (weighted) mean center until a good enough
approximation is found.

=head2 FUNCTIONS

=over 2

=item median_center(\%options)

Computes the median center of a list of points. Options are C<points>,
an array of arrays of latitude and longitude in decimal degrees and
optionally a weight; C<tolerance>, a number in meters, if the iterative
algorithm improves its approximation by at most this value, the function
will return; C<max_iterations>, the function will return after this
many attempts to refine the approximation. Returns the latitude and
longitude in decimal degrees.

=item haversine_distance_dec($lat1, $lon1, $lat2, $long2)

Computes the distance between the two points using the Haversine
formula in meters. Latitude and longitude are specified in decimal
degrees.

=item haversine_distance_rad($lat1, $lon1, $lat2, $long2)

Computes the distance between the two points using the Haversine
formula in meters. Latitude and longitude are specified in radians.

=back

=head2 EXPORT

The function C<median_center> is exported by default, the other
functions on request.

=head1 BUG REPORTS

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-MedianCenter-XS>

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2010 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut

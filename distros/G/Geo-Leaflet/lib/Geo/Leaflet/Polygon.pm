package Geo::Leaflet::Polygon;
use strict;
use warnings;
use base qw{Geo::Leaflet::Objects};

our $VERSION = '0.04';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Leaflet::Polygon - Leaflet polygon object

=head1 SYNOPSIS

  use Geo::Leaflet;
  my $map     = Geo::Leaflet->new;
  my $polygon = $map->polygon(
                              coordinates => [[$lat, $lon], ...]
                              options     => {},
                             );

=head1 DESCRIPTION

This package constructs a Leaflet polygon object for use on a L<Geo::Leaflet> map.

=head1 PROPERTIES

=head2 coordinates

=cut

sub coordinates {
  my $self       = shift;
  $self->{'coordinates'} = shift if @_;
  die("Error: coordinates required") unless defined $self->{'coordinates'};
  return $self->{'coordinates'};
}

=head2 options

=head2 popup

=head1 METHODS

=head2 stringify

=cut

sub _method_name {'polygon'};

sub stringify {
  my $self = shift;
#   const polygon = L.polygon([
#       [51.509, -0.08],
#       [51.503, -0.06],
#       [51.51, -0.047]
#   ]).addTo(map).bindPopup('I am a polygon.');
  return $self->stringify_base($self->coordinates);
}

=head1 SEE ALSO

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

=cut

1;

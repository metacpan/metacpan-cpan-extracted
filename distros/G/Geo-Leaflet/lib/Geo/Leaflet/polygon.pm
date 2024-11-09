package Geo::Leaflet::polygon;
use strict;
use warnings;
use base qw{Geo::Leaflet::Base};

our $VERSION = '0.01';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Leaflet::polygon - Generates Leaflet web page

=head1 SYNOPSIS

  use Geo::Leaflet;
  my $map     = Geo::Leaflet->new;
  my $polygon = $map->polygon(
                              coordinates => [[$lat, $lon], ...]
                              properties  => {},
                             );

=head1 DESCRIPTION

The package is designed to be able to build a Leaflet map similar to what L<Geo::Google::StaticMaps::V2> used to be able to provide.

=head1 PROPERTIES

=head2 coordinates

=cut

sub coordinates {
  my $self       = shift;
  $self->{'coordinates'} = shift if @_;
  die("Error: coordinates required") unless defined $self->{'coordinates'};
  return $self->{'coordinates'};
}

=head2 properties

=head2 popup

=head1 METHODS

=head2 stringify

=cut

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

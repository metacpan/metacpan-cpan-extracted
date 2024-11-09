package Geo::Leaflet::marker;
use strict;
use warnings;
use base qw{Geo::Leaflet::Base};

our $VERSION = '0.01';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Leaflet::marker - Generates Leaflet web page

=head1 SYNOPSIS

  use Geo::Leaflet;
  my $map    = Geo::Leaflet->new;
  my $marker = $map->marker(
                            lat => $lat,
                            lon => $lon,
                           );

=head1 DESCRIPTION

The package is designed to be able to build a Leaflet map similar to what L<Geo::Google::StaticMaps::V2> used to be able to provide.

=head1 PROPERTIES

=head2 lat

=cut

sub lat {
  my $self       = shift;
  $self->{'lat'} = shift if @_;
  die("Error: lat required") unless defined $self->{'lat'};
  return $self->{'lat'};
}

=head2 lon

=cut

sub lon {
  my $self       = shift;
  $self->{'lon'} = shift if @_;
  die("Error: lon required") unless defined $self->{'lon'};
  return $self->{'lon'};
}

=head2 properties

=head2 popup

=head1 METHODS

=head2 stringify

=cut

sub stringify {
  my $self = shift;
  #const marker = L.marker([51.5, -0.09]).addTo(map);
  return $self->stringify_base([$self->lat, $self->lon]);
}

=head1 SEE ALSO

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

=cut

1;

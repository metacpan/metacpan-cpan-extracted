package Geo::Leaflet::tileLayer;
use strict;
use warnings;
use base qw{Geo::Leaflet::Base};

our $VERSION = '0.02';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Leaflet::tileLayer - Leaflet tileLayer Object

=head1 SYNOPSIS

  use Geo::Leaflet;
  my $map       = Geo::Leaflet->new;
  my $tileLayer = $map->tileLayer(
                                  url     => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  options => {
                                    maxZoom     => 19,
                                    attribution => '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
                                  }
                                 );

=head1 DESCRIPTION

This package constructs a Leaflet tileLayer object for use on a L<Geo::Leaflet> map.

=head1 CONSTRUCTORS

=head2 new

Returns a tileLayer object

=head2 osm

Returns the default OpenStreetMaps.org tileLayer.

  my $tileLayer = Geo::Leaflet::tileLayer->osm;

=cut

sub osm {
  my $self = shift;
  return $self->new(
                    url     => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    options => {
                      maxZoom     => 19,
                      attribution => '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
                    },
                    @_,
                   );
}

=head1 PROPERTIES

=head2 url

=cut

sub url {
  my $self       = shift;
  $self->{'url'} = shift if @_;
  die("Error: url required") unless $self->{'url'};
  return $self->{'url'};
}

=head1 METHODS

=head2 stringify

=cut

sub stringify {
  my $self = shift;
  #L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png?{foo}', {foo: 'bar', attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'}).addTo(map);
  return $self->stringify_base($self->url);
}

=head1 SEE ALSO

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

=cut

1;

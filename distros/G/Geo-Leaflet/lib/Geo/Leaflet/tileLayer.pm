package Geo::Leaflet::tileLayer;
use strict;
use warnings;
use base qw{Package::New};

our $VERSION = '0.01';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Leaflet::tileLayer - Generates a Leaflet tileLayer Object

=head1 SYNOPSIS

  use Geo::Leaflet;
  my $map       = Geo::Leaflet->new;
  my $tileLayer = $map->tileLayer(
                                  url         => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  maxZoom     => 19,
                                  attribution => '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
                                 );

=head1 DESCRIPTION

The package generates a Leaflet tileLayer Object

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
                    url         => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    maxZoom     => 19,
                    attribution => '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
                    @_,
                   );
}

=head1 PROPERTIES

=head2 url

=cut

sub url {
  my $self        = shift;
  $self->{'url'} = shift if @_;
  die("Error: url required") unless $self->{'url'};
  return $self->{'url'};
}

=head2 maxZoom

=cut

sub maxZoom {
  my $self           = shift;
  $self->{'maxZoom'} = shift if @_;
  die("Error: maxZoom required") unless $self->{'maxZoom'};
  die("Error: maxZoom must be integer") unless $self->{'maxZoom'} =~ m/\A[1-9][0-9]*\Z/;
  return $self->{'maxZoom'};
}

=head2 attribution

=cut

sub attribution {
  my $self               = shift;
  $self->{'attribution'} = shift if @_;
  $self->{'attribution'} = '' unless $self->{'attribution'};
  die("Error: attribution cannot contain single quote") if $self->{'attribution'} =~ m/'/;
  return $self->{'attribution'};
}

=head1 METHODS

=head2 stringify

=cut

sub stringify {
  my $self = shift;
  return sprintf(q[const tiles = L.tileLayer('%s', {maxZoom: %d, attribution: '%s' }).addTo(map);], 
                 $self->url,
                 $self->maxZoom,
                 $self->attribution,
                );
}

=head1 SEE ALSO

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

=cut

1;

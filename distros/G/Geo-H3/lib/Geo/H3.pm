package Geo::H3;
use strict;
use warnings;
use base qw{Geo::H3::Base}; #provides new and ffi
use Geo::H3::Index;
use Geo::H3::Geo;

our $VERSION = '0.09';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::H3 - H3 Geospatial Hexagon Indexing System

=head1 SYNOPSIS

  use Geo::H3;
  my $gh3      = Geo::H3->new;
  
  my $hex      = $gh3->h3(uint64 => $int);        #isa Geo::H3::Index
  my $hex      = $gh3->h3(string => $string);     #isa Geo::H3::Index

  my $geo      = $gh3->geo(lat=>$lat, lon=>$lon); #isa Geo::H3::Geo
  my $hex      = $geo->h3($resolution);           #isa Geo::H3::Index

  my $center   = $h3->center;                     #isa Geo::H3::GeoCoord
  my $lat      = $center->lat;                    #isa Double WGS-84 Decimal Degrees
  my $lon      = $center->lon;                    #isa Double WGS-84 Decimal Degrees
  my $distance = $center->distance($geo);         #isa Double meters
  
=head1 DESCRIPTION

This Perl distribution provides a Perl Object Oriented interface to the H3 Core Library.  It accesses the H3 C library using L<libffi|https://github.com/libffi/libffi> and L<FFI::Platypus>.

H3 is a geospatial indexing system that partitions the world into hexagonal cells. Please note that a very few number of cells are pentagons but we use the terms hex or hexagon to include pentagons.

The H3 Core Library implements the H3 grid system. It includes functions for converting from latitude and longitude coordinates to the containing H3 cell, finding the center of H3 cells, finding the boundary geometry of H3 cells, finding neighbors of H3 cells, and more.

The H3 Core Library can be installed from Uber's H3 repository on GitHub L<https://github.com/uber/h3> which is well documented at L<https://h3geo.org/docs/>.  

=head2 CONVENTIONS

The Geo::H3 lib is an Object Oriented wrapper on top of the L<Geo::H3::FFI> library.  Geo::H3 was written as a wrapper so that in the future we are able to re-write against different backends such as the yet to be developed Geo::H3::XS backend.

=head3 libh3

  - Latitude and longitude cordinates are in radians WGS-84
  - H3 Index values are handled as uint64 integers
  - GeoCoord values are handled as C structures with lat and lon
  - GeoBoundary values are handled as C structures with num_verts and verts

=head3 Geo::H3::FFI

  - Latitude and Longitude cordinates are in radians WGS-84
  - H3 Index values are handled as uint64 integers
  - GeoCoord values are handled as Geo::H3::FFI::Struct::GeoCoord objects
  - GeoBoundary values are handled as Geo::H3::FFI::Struct::GeoBoundary objects

=head3 Geo::H3

  - Latitude and longitue cordinates are in decimal degrees WGS-84
  - H3 Index values are handled as Geo::H3::Index objects
  - GeoCoord values are handled as Geo::H3::GeoCoord objects
  - GeoBoundary values are handled as Geo::H3::GeoBoundary objects

=head1 CONSTRUCTORS

=head2 h3

Returns a L<Geo::H3::Index> object

  my $hex = $gh3->h3(unit64 => $int);                  #isa Geo::H3::Index
  my $hex = $gh3->h3(string => $string);               #isa Geo::H3::Index
  my $hex = Geo::H3::Index->new(uint64 => $h3_uint64); #isa Geo::H3::Index
  my $hex = Geo::H3::Index->new(string => $h3_string); #isa Geo::H3::Index

=cut

sub h3 {
  my $self     = shift;
  my %data     = @_;
  $data{'ffi'} = $self->ffi unless exists $data{'ffi'};
  return Geo::H3::Index->new(%data);
}

=head2 geo

Returns a L<Geo::H3::Geo> object

  my $geo = $gh3->geo(lat=>$lat_deg, lon=>$lon_deg);         #isa Geo::H3::Geo
  my $geo = Geo::H3::Geo->new(lat=>$lat_deg, lon=>$lon_deg); #isa Geo::H3::Geo

=cut

sub geo {
  my $self     = shift;
  my %data     = @_;
  $data{'ffi'} = $self->ffi unless exists $data{'ffi'};
  return Geo::H3::Geo->new(%data);
};

=head2 ffi

Returns the L<Geo::H3::FFI> object.

=head1 LIMITATIONS

This package uses the naming convention of version 3.x of the Uber H3 library.  The organization that maintains the open source Uber H3 library has not maintained backward compatibility in version 4.x.  This Perl distribution currently sees no reason to support the 4.x version of the Uber H3 library as the 3.7.2 release is stable and full featured.

=head1 SEE ALSO

L<https://h3geo.org/docs/3.x/>, L<https://github.com/uber/h3/tree/stable-3.x>, L<Geo::H3::FFI>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2021 Michael R. Davis

=cut

1;

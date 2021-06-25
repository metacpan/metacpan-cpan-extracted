package Geo::H3;
use strict;
use warnings;
use base qw{Geo::H3::Base}; #provides new and ffi
use Geo::H3::Index;
use Geo::H3::Geo;

our $VERSION = '0.06';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::H3 - H3 Geospatial Hexagon Indexing System

=head1 SYNOPSIS

  use Geo::H3;
  my $gh3      = Geo::H3->new;
  
  my $h3       = $gh3->h3(index  => $int);        #isa Geo::H3::Index
  my $h3       = $gh3->h3(string => $string);     #isa Geo::H3::Index

  my $geo      = $gh3->geo(lat=>$lat, lon=>$lon); #isa Geo::H3::Geo
  my $h3       = $geo->h3($resolution);           #isa Geo::H3::Index

  my $center   = $h3->center;                     #isa Geo::H3::GeoCoord
  my $lat      = $center->lat;                    #isa Double WGS-84 Decimal Degrees
  my $lon      = $center->lon;                    #isa Double WGS-84 Decimal Degrees
  my $distance = $center->pointDistM($geo);       #isa Double meters
  
=head1 DESCRIPTION

This Perl distribution provides a Perl Object Oriented interface to the H3 Core Library.  It accesses the H3 C library using L<libffi|https://github.com/libffi/libffi> and L<FFI::Platypus>.

H3 is a geospatial indexing system that partitions the world into hexagonal cells.

The H3 Core Library implements the H3 grid system. It includes functions for converting from latitude and longitude coordinates to the containing H3 cell, finding the center of H3 cells, finding the boundary geometry of H3 cells, finding neighbors of H3 cells, and more.

The H3 Core Library can be installed from Uber's H3 repository on GitHub L<https://github.com/uber/h3> which is well documented at L<https://h3geo.org/docs/>.  

=head2 CONVENTIONS

The Geo::H3 lib is an Object Oriented wrapper on top of the L<Geo::H3::FFI> library.  Geo::H3 was written as a wrapper so that in the future we are able to re-write against different backends such as the yet to be developed Geo::H3::XS backend.

=head3 libh3

  - Latitude and longitue cordinates are in radians WGS-84
  - H3 Index values are handled as uint64 integers
  - GeoCoord values are handled as C structures with lat and lon
  - GeoBoundary values are handled as C structures with num_verts and verts

=head3 Geo::H3::FFI

  - Latitude and Longitue cordinates are in radians WGS-84
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

  my $h3 = $gh3->h3(index  => $int);             #isa Geo::H3::Index
  my $h3 = $gh3->h3(string => $string);          #isa Geo::H3::Index
  my $h3 = Geo::H3::Index->new(index => $index); #isa Geo::H3::Index

=cut

sub h3 {
  my $self   = shift;
  my %data   = @_;
  my $index  = $data{'index'};
  my $string = $data{'string'};
  if ($index) {
    return Geo::H3::Index->new(index => $index, ffi => $self->ffi);
  } elsif ($string) {
    my $index = $self->ffi->stringToH3Wrapper($string) or die("Error: package $PACKAGE constructor h3 string invalid");
    return Geo::H3::Index->new(index => $index, ffi => $self->ffi);
  } else {
    die("Error: package $PACKAGE constructor h3 requires either index or string");
  }
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

=head1 SEE ALSO

L<https://h3geo.org/>, L<https://github.com/uber/h3/>, L<Geo::H3::FFI>

=head1 INSTALLATION

L<Geo::H3> has some pretty deep requirements that are not available in many OS repositories.  For RedHat and CentOS 7 users, I have have built RPMs and placed them on my L<Linux Yum Repository|http://linux.davisnetworks.com/el7/>

To install the distribution with all dependencies - CentOS 7

  $ sudo yum install http://linux.davisnetworks.com/el7/updates/mrdvt92-release-8-2.el7.mrdvt92.noarch.rpm
  $ sudo yum install 'perl(Geo::H3)'

To install the additional dependencies for the example script perl-Geo-H3-geo-to-googleearth.pl

  $ sudo yum install 'perl(Geo::GoogleEarth::Pluggable)' 'perl(Geo::GoogleEarth::Pluggable::Plugin::Styles)' 'perl(Path::Class)'

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2021 Michael R. Davis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

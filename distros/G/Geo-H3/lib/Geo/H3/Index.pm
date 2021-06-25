package Geo::H3::Index;
use strict;
use warnings;
use base qw{Geo::H3::Base}; #provides new and ffi
require Geo::H3::Geo;
require Geo::H3::GeoBoundary;

our $VERSION = '0.06';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::H3::Index - H3 Geospatial Hexagon Indexing System Index Object

=head1 SYNOPSIS

  use Geo::H3::Index;
  my $h3       = Geo::H3::Index->new(index=$index); #isa Geo::H3::Index
  my $centroid = $h3->geo;                          #isa Geo::H3::GeoCoord
  my $lat      = $center->lat;                      #isa double WGS-84 Decimal Degrees
  my $lon      = $center->lon;                      #isa double WGS-84 Decimal Degrees

=head1 DESCRIPTION

H3 Geospatial Hexagon Indexing System Index Object provides the primary interface for working with H3 Indexes.



=head1 CONSTRUCTORS

=head2 new

  my $geo = Geo::H3::Index->new(index=>$index);

=cut

sub _bless_aref {
  my $self = shift;
  my $aref = shift;
  return [map {Geo::H3::Index->new(index=>$_)} @$aref];
}

=head1 PROPERTIES

=head2 index

Returns the H3 index uint64 representation

=cut

sub index {
  my $self = shift;
  return $self->{'index'};
}

=head2 string

Returns the H3 string representation.

=cut

sub string {
  my $self = shift;
  return sprintf("%x", $self->index);
}

=head2 resolution

Returns the resolution of the index.

=cut

sub resolution {
  my $self = shift;
  return $self->ffi->h3GetResolution($self->index);
}

=head2 baseCell

Returns the base cell number of the index.

=cut

sub baseCell {
  my $self = shift;
  return $self->ffi->h3GetBaseCell($self->index);
}

=head2 isValid

Returns non-zero if this is a valid H3 index.

=cut

sub isValid {
  my $self = shift;
  return $self->ffi->h3IsValid($self->index);
}

=head2 isResClassIII

Returns non-zero if this index has a resolution with Class III orientation.

=cut

sub isResClassIII {
  my $self = shift;
  return $self->ffi->h3IsResClassIII($self->index);
}

=head2 isPentagon

Returns non-zero if this index represents a pentagonal cell.

=cut

sub isPentagon {
  my $self = shift;
  return $self->ffi->h3IsPentagon($self->index);
}

=head2 maxFaceCount

Returns the maximum number of icosahedron faces the given H3 index may intersect.

=cut

sub maxFaceCount {
  my $self = shift;
  return $self->ffi->maxFaceCount($self->index);
}

=head2 area

Returns the area in square meters of this index.

=cut

sub area {
  my $self = shift;
  return $self->ffi->cellAreaM2($self->index);
}

=head2 areaApprox

Returns the average area in square meters of indexes at this resolution.

=cut

sub areaApprox {
  my $self = shift;
  return $self->ffi->hexAreaM2($self->resolution);
}

=head2 edgeLength

Returns the exact edge length in meters of this index.

=cut

sub edgeLength {
  my $self = shift;
  return $self->ffi->exactEdgeLengthM($self->index);
}

=head2 edgeLengthApprox

Returns the average edge length in meters of indexes at this resolution.

=cut

sub edgeLengthApprox {
  my $self = shift;
  return $self->ffi->edgeLengthM($self->resolution);
}

=head1 METHODS

=head2 geo

Returns the centroid of the index as a L<Geo::H3::Geo> object.

=cut

sub geo {
  my $self = shift;
  my $geo  = $self->ffi->h3ToGeoWrapper($self->index);
  my $lat  = $self->ffi->radsToDegs($geo->lat);
  my $lon  = $self->ffi->radsToDegs($geo->lon);
  return Geo::H3::Geo->new(lat=>$lat, lon=>$lon, ffi=>$self->ffi);
}

=head2 geoBoundary

Returns the boundary of the index as a L<Geo::H3::GeoBoundary> object

=cut

sub geoBoundary {
  my $self = shift;
  return Geo::H3::GeoBoundary->new(gb=>$self->ffi->h3ToGeoBoundaryWrapper($self->index), ffi=>$self->ffi);
}

=head2 parent

Returns a parent index of this index as a L<Geo::H3::Index> object.

  my $parent = $h3->parent;    #next larger resolution
  my $parent = $h3->parent(1); #isa Geo::H3::Index

=cut

sub parent {
  my $self       = shift;
  my $resolution = shift || $self->resolution - 1;
  return Geo::H3::Index->new(index=>$self->ffi->h3ToParent($self->index, $resolution));
}

=head2 children

Returns the children of the index as an array reference of L<Geo::H3::Index> objects.

  my $children = $h3->children(12); #isa ARRAY
  my $children = $h3->children;     #next smaller resolution

=cut

sub children {
  my $self       = shift;
  my $resolution = shift || $self->resolution + 1;
  return $self->_bless_aref($self->ffi->h3ToChildrenWrapper($self->index, $resolution));
}

=head2 centerChild

Returns the center child (finer) index contained by this index at given resolution.

  my $centerChild = $index->centerChild;      #isa Geo::H3::Index
  my $centerChild = $index->centerChild(12);  #isa Geo::H3::Index

=cut

sub centerChild {
  my $self       = shift;
  my $resolution = shift || $self->resolution + 1;
  return Geo::H3::Index->new(index=>$self->ffi->h3ToCenterChild($self->index, $resolution));
}

=head2 kRing

Returns k-rings indexes within k distance of the origin index.

  my $list $index->kRing($k); #isa ARRAY of L<Geo::H3::Index> objects

=cut

sub kRing {
  my $self = shift;
  my $k    = shift || 1;
  return $self->_bless_aref($self->ffi->kRingWrapper($self->index, $k));
}

=head2 kRingDistances

Returns a hash reference where the keys are the H3 index and values are the k distance for the given index and k value.

  my $hash = $index->kRingDistances($k);

=cut

sub kRingDistances {
  my $self = shift;
  my $k    = shift || 1;
  return $self->ffi->kRingDistancesWrapper($self->index, $k);
}

=head2 hexRange

  my $indexes = $index->hexRange($k);

=cut

sub hexRange {
  my $self = shift;
  my $k    = shift || 1;
  return $self->_bless_aref($self->ffi->hexRangeWrapper($self->index, $k));
}

=head2 hexRangeDistances

Returns a hash reference where the keys are the H3 index and values are the k distance for the given index and k value.

  my $hash = $index->hexRangeDistances($k);

=cut

sub hexRangeDistances {
  my $self = shift;
  my $k    = shift || 1;
  return $self->ffi->hexRangeDistancesWrapper($self->index, $k);
}

=head2 hexRing

Returns the hex ring of this index as an array reference of L<Geo::H3::Index> objects

  my $hexes = $h3->hexRing; #default k = 1
  my $hexes = $h3->hexRing(5); #isa ARRAY

=cut

sub hexRing {
  my $self = shift;
  my $k    = shift || 1;
  return $self->_bless_aref($self->ffi->hexRingWrapper($self->index, $k));
}

=head2 areNeighbors

Returns whether or not the provided H3Indexes are neighbors.

  my $areNeighbors = $start_index->areNeighbors($end_index);

=cut

sub areNeighbors {
  my $self = shift;
  my $end  = shift;
  return $self->_bless_aref($self->ffi->h3IndexesAreNeighbors($self->index, $end->index));
}

=head2 line

Returns the indexes starting at this index to the given end index as array reference of L<Geo::H3::Index> objects.

  my $list_aref = $start_index->line($end_index);

=cut

sub line {
  my $self = shift;
  my $end  = shift;
  return $self->_bless_aref($self->ffi->h3LineWrapper($self->index, $end->index));
}

=head2 distance

Returns the distance in grid cells between this index to the given end index.

  my $distance = $start_index->distance($end_index);

=cut

sub distance {
  my $self = shift;
  my $end   = shift;
  return $self->h3Distance($self->index, $end->index);
}

=head1 SEE ALSO

L<Geo::H3>, L<Geo::H3::FFI>

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

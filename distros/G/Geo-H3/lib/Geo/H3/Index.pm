package Geo::H3::Index;
use strict;
use warnings;
use base qw{Geo::H3::Base}; #provides new and ffi
require Geo::H3::Geo;
require Geo::H3::GeoBoundary;

our $VERSION = '0.09';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::H3::Index - H3 Geospatial Hexagon Indexing System Index Object

=head1 SYNOPSIS

  use Geo::H3::Index;
  my $h3       = Geo::H3::Index->new(string => $string); #isa Geo::H3::Index
  my $center   = $h3->geo;                             #isa Geo::H3::Geo
  my $lat      = $center->lat;                         #isa double WGS-84 Decimal Degrees
  my $lon      = $center->lon;                         #isa double WGS-84 Decimal Degrees
  my $boundary = $h3->geoBoundary;                     #isa Geo::H3::GeoBoundary

=head1 DESCRIPTION

H3 Geospatial Hexagon Indexing System Index Object provides the primary interface for working with H3 Indexes.

=head1 CONSTRUCTORS

=head2 new

  my $h3 = Geo::H3::Index->new(string=>$string);
  my $h3 = Geo::H3::Index->new(uint64=>$uint64);

=cut

sub _bless_aref {
  my $self = shift;
  my $aref = shift;
  return [map {Geo::H3::Index->new(uint64=>$_, ffi=>$self->ffi)} @$aref];
}

=head1 PROPERTIES

=head2 string

Returns the H3 string representation.

=cut

sub string {
  my $self = shift;
  unless ($self->{'string'}) {
    if (defined($self->{'uint64'})) {
      $self->{'string'} = $self->ffi->h3ToStringWrapper($self->{'uint64'});
    } elsif (defined($self->{'index'})) {
      if ($self->{'index'} =~ m/\A[0-9a-f]{15}\Z/) { #821c07fffffffff
        $self->{'string'} = $self->{'index'};
      } else {
        $self->{'string'} = $self->ffi->h3ToStringWrapper($self->{'index'});
      }
    }
  }
  return $self->{'string'};
}

=head2 uint64

Returns the H3 uint64 representation.

=cut

sub uint64 {
  my $self = shift;
  unless ($self->{'uint64'}) {
    $self->{'uint64'} = $self->ffi->stringToH3Wrapper($self->string);
  }
  return $self->{'uint64'};
}

=head2 index (DEPRECATED)

Returns the H3 uint64 representation.

Please note that `index()` was difficult to remember consistently.  Therefore, I plan to move to the `uint64()` property moving forward while maintaining backwards compatibility.

=cut

sub index {
  my $self = shift;
  $self->{'index'} = $self->{'uint64'} unless $self->{'index'};
  return $self->{'index'};
}

=head2 resolution

Returns the resolution of the hex.

=cut

sub resolution {
  my $self = shift;
  return $self->ffi->h3GetResolution($self->uint64);
}

=head2 baseCell

Returns the base cell number of the hex.

=cut

sub baseCell {
  my $self = shift;
  return $self->ffi->h3GetBaseCell($self->uint64);
}

=head2 isValid

Returns non-zero if this is a valid H3 hex.

=cut

sub isValid {
  my $self = shift;
  return $self->ffi->h3IsValid($self->uint64);
}

=head2 isResClassIII

Returns non-zero if this hex has a resolution with Class III orientation.

=cut

sub isResClassIII {
  my $self = shift;
  return $self->ffi->h3IsResClassIII($self->uint64);
}

=head2 isPentagon

Returns non-zero if this hex represents a pentagonal cell.

=cut

sub isPentagon {
  my $self = shift;
  return $self->ffi->h3IsPentagon($self->uint64);
}

=head2 maxFaceCount

Returns the maximum number of icosahedron faces the given H3 hex may intersect.

=cut

sub maxFaceCount {
  my $self = shift;
  return $self->ffi->maxFaceCount($self->uint64);
}

=head2 area

Returns the area in square meters of this hex.

=cut

sub area {
  my $self = shift;
  return $self->ffi->cellAreaM2($self->uint64);
}

=head2 areaApprox

Returns the average area in square meters of hexes at this resolution.

=cut

sub areaApprox {
  my $self = shift;
  return $self->ffi->hexAreaM2($self->resolution);
}

=head2 edgeLength

Returns the exact edge length in meters of this hex.

=cut

sub edgeLength {
  my $self = shift;
  return $self->ffi->exactEdgeLengthM($self->uint64);
}

=head2 edgeLengthApprox

Returns the average edge length in meters of hexes at this resolution.

=cut

sub edgeLengthApprox {
  my $self = shift;
  return $self->ffi->edgeLengthM($self->resolution);
}

=head1 METHODS

=head2 geo

Returns the centroid of the hex as a L<Geo::H3::Geo> object.

=cut

sub geo {
  my $self = shift;
  my $geo  = $self->ffi->h3ToGeoWrapper($self->uint64);
  my $lat  = $self->ffi->radsToDegs($geo->lat);
  my $lon  = $self->ffi->radsToDegs($geo->lon);
  return Geo::H3::Geo->new(lat=>$lat, lon=>$lon, ffi=>$self->ffi);
}

=head2 geoBoundary

Returns the boundary of the hex as a L<Geo::H3::GeoBoundary> object

=cut

sub geoBoundary {
  my $self = shift;
  return Geo::H3::GeoBoundary->new(gb=>$self->ffi->h3ToGeoBoundaryWrapper($self->uint64), ffi=>$self->ffi);
}

=head2 parent

Returns a parent hex of this hex as a L<Geo::H3::Index> object.

  my $parent = $h3->parent;    #next larger resolution
  my $parent = $h3->parent(1); #isa Geo::H3::Index

=cut

sub parent {
  my $self       = shift;
  my $resolution = shift || $self->resolution - 1;
  return Geo::H3::Index->new(uint64=>$self->ffi->h3ToParent($self->uint64, $resolution), ffi=>$self->ffi);
}

=head2 children

Returns the children of the hex as an array reference of L<Geo::H3::Index> objects.

  my $children = $h3->children(12); #isa ARRAY
  my $children = $h3->children;     #next smaller resolution

=cut

sub children {
  my $self       = shift;
  my $resolution = shift || $self->resolution + 1;
  return $self->_bless_aref($self->ffi->h3ToChildrenWrapper($self->uint64, $resolution));
}

=head2 centerChild

Returns the center child (finer) hex contained by this hex at given resolution.

  my $centerChild = $hex->centerChild;      #isa Geo::H3::Index
  my $centerChild = $hex->centerChild(12);  #isa Geo::H3::Index

=cut

sub centerChild {
  my $self       = shift;
  my $resolution = shift || $self->resolution + 1;
  return Geo::H3::Index->new(uint64=>$self->ffi->h3ToCenterChild($self->uint64, $resolution), ffi=>$self->ffi);
}

=head2 kRing

Returns k-rings hexes within k distance of the origin hex.

  my $hexes_aref = $hex->kRing($k); #isa ARRAY of L<Geo::H3::Index> objects

=cut

sub kRing {
  my $self = shift;
  my $k    = shift || 1;
  return $self->_bless_aref($self->ffi->kRingWrapper($self->uint64, $k));
}

=head2 kRingDistances

Returns a hash reference where the keys are the H3 hex and values are the k distance for the given hex and k value.

  my $distances_aref = $hex->kRingDistances($k); #isa ARRAY-ARRAY [ [$hex1, $dist1], [$hex2, $dist2], ... [$hexN, $distN] ]

=cut

sub kRingDistances {
  my $self = shift;
  my $k    = shift || 1;
  my $aref = $self->ffi->kRingDistancesWrapperArray($self->uint64, $k); #isa ARRAY-ARRAY [[$uint64, $k_distance], ..]
  $_->[0]  = $self->new(uint64=>$_->[0]) foreach @$aref; #bless uint64 column
  return $aref;
}

=head2 hexRange

Returns an array reference of hexes within k distance of the hex object. k-ring 0 is defined as the origin index, k-ring 1 is defined as k-ring 0 and all neighboring indexes, and so on.

  my $hexes_aref = $hex->hexRange($k);

=cut

sub hexRange {
  my $self = shift;
  my $k    = shift || 1;
  return $self->_bless_aref($self->ffi->hexRangeWrapper($self->uint64, $k));
}

=head2 hexRangeDistances

Returns a hash reference where the keys are the H3 uint64 and values are the k distance for the given hex and k value.

  my $hash = $hex->hexRangeDistances($k); #isa ARRAY-ARRAY [ [$hex1, $dist1], [$hex2, $dist2], ... [$hexN, $distN] ]

=cut

sub hexRangeDistances {
  my $self = shift;
  my $k    = shift || 1;
  my $aref = $self->ffi->hexRangeDistancesWrapperArray($self->uint64, $k); #isa ARRAY-ARRAY [[$uint64, $k_distance], ..]
  $_->[0]  = $self->new(uint64=>$_->[0]) foreach @$aref; #bless uint64 column
  return $aref;
}

=head2 hexRing

Returns the hex ring of this hex as an array reference of L<Geo::H3::Index> objects

  my $hexes = $h3->hexRing; #default k = 1
  my $hexes = $h3->hexRing(5); #isa ARRAY

=cut

sub hexRing {
  my $self = shift;
  my $k    = shift || 1;
  return $self->_bless_aref($self->ffi->hexRingWrapper($self->uint64, $k));
}

=head2 areNeighbors

Returns a 1 or 0 based on whether or not the provided hex object is a neighbor.

  my $areNeighbors = $start_hex->areNeighbors($end_hex);

=cut

sub areNeighbors {
  my $self = shift;
  my $end  = shift;
  return $self->ffi->h3IndexesAreNeighbors($self->uint64, $end->uint64);
}

=head2 line

Returns the hexes starting at this hex to the given end hex as array reference of L<Geo::H3::Index> objects.

  my $list_aref = $start_hex_obj->line($end_hex_obj);

=cut

sub line {
  my $self = shift;
  my $end  = shift;
  return $self->_bless_aref($self->ffi->h3LineWrapper($self->uint64, $end->uint64));
}

=head2 distance

Returns the distance in grid cells between this hex to the given end hex.

  my $distance = $start_hex_obj->distance($end_hex_obj);

=cut

sub distance {
  my $self = shift;
  my $end  = shift;
  return $self->ffi->h3Distance($self->uint64, $end->uint64);
}

=head1 SEE ALSO

L<Geo::H3>, L<Geo::H3::FFI>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2021 Michael R. Davis

=cut

1;

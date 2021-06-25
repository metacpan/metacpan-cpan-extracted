package Geo::H3::FFI;
use strict;
use warnings;
use base qw{Package::New};
use FFI::CheckLib qw{};
use FFI::Platypus qw{};
use FFI::C qw{};

our $PACKAGE = __PACKAGE__;
our $VERSION = '0.06';

my $lib = FFI::CheckLib::find_lib_or_die(lib => 'h3');
my $ffi = FFI::Platypus->new(api => 1, lib => $lib);
FFI::C->ffi($ffi); #Beware: Class setting

$ffi->type('uint64_t[]' => 'uint64_t_array');
$ffi->type('int[]'      => 'int_array');
package Geo::H3::FFI::Struct::GeoCoord    {FFI::C->struct(geo_coord_t       => [lat         => 'double', lon   => 'double'           ])};
package Geo::H3::FFI::Array::GeoCoord     {FFI::C->array (array_geo_coord_t => [geo_coord_t => 10                                    ])};
package Geo::H3::FFI::Struct::GeoBoundary {FFI::C->struct(geo_boundary_t    => [num_verts   => 'int'   , verts => 'array_geo_coord_t'])};

sub _oowrapper {
  my $xs   = shift;
  my $self = shift;
  return $xs->(@_);
}

=head1 NAME

Geo::H3::FFI - Perl FFI binding to H3 library functions

=head1 SYNOPSIS

  use Geo::H3::FFI;

=head1 DESCRIPTION

Perl FFI binding to H3 library functions

=head1 CONSTRUCTORS

=head2 new

  my $gh3 = Geo::H3::FFI->new;

=head2 geo

Returns a GeoCoord struct

  my $geo = $gh3->geo; #empty struct                 #isa Geo::H3::FFI::Struct::GeoCoord
  my $geo = $gh3->geo(lat=>$lat_rad, lon=>$lon_rad); #isa Geo::H3::FFI::Struct::GeoCoord

=cut

sub geo {
  my $self = shift;
  my %hash = @_;
  return Geo::H3::FFI::Struct::GeoCoord->new(\%hash);
}

=head2 gb

Returns a GeoBoundary struct

  my $gb = $gh3->gb; #empty struct      #isa Geo::H3::FFI::Struct::GeoBoundary

=cut

sub gb {
  my $self = shift;
  my %hash = @_;
  return Geo::H3::FFI::Struct::GeoBoundary->new(\%hash);
}

=head1 Indexing Functions

These function are used for finding the H3 index containing coordinates, and for finding the center and boundary of H3 indexes.

=head2 geoToH3

Indexes the location at the specified resolution, returning the index of the cell containing the location.

  my $geo        = $gh3->geo(lat=>$lat_rad, lon=>$lon_rad);   #isa Geo::H3::FFI::Struct::GeoCoord
  my $resolution = 8;                                         #isa Int in (0 .. 15)
  my $index      = $gh3->geoToH3($geo, $resolution);          #isa Int64

Returns 0 on error.

=cut

#H3Index geoToH3(const GeoCoord *g, int res);
$ffi->attach(geoToH3 => ['geo_coord_t', 'int'] => 'uint64_t' => \&_oowrapper);

=head2 geoToH3Wrapper

  my $index = $gh3->geoToH3Wrapper(lat=>$lat_rad, lon=>$lon_rad, resolution=>$resolution);
  my $index = $gh3->geoToH3Wrapper(lat=>$lat,     lon=>$lon,     resolution=>$resolution, uom=>"deg");

=cut

sub geoToH3Wrapper {
  my $self  = shift;
  my %input = @_;
  my $lat   = $input{'lat'}; die unless defined $lat;
  my $lon   = $input{'lon'}; die unless defined $lon;
  my $uom   = $input{'uom'} || 'rad';
  if ($uom eq "deg") {
    $lat = $self->degsToRads($lat);
    $lon = $self->degsToRads($lon);
  }
  my $res   = $input{'resolution'} || 0;
  my $geo   = $self->geo(lat=>$lat, lon=>$lon); #isa Geo::H3::FFI::Struct::GeoCoord
  my $index = $self->geoToH3($geo, $res);       #isa Int64
  return $index;
}

=head2 h3ToGeo

Finds the centroid of the index.

  my $geo = $gh3->geo;          #isa Geo::H3::FFI::Struct::GeoCoord
  $gh3->h3ToGeo($index, $geo);
  my $lat = $geo->lat;          #isa Float in radians
  my $lon = $geo->lon;          #isa Float in radians

=cut

#void h3ToGeo(H3Index h3, GeoCoord *g);
$ffi->attach(h3ToGeo => ['uint64_t', 'geo_coord_t'] => 'void' => \&_oowrapper);

=head2 h3ToGeoWrapper

  my $geo = h3ToGeoWrapper($index); #isa Geo::H3::FFI::Struct::GeoCoord
  my $lat = $geo->lat;          #isa Float in radians
  my $lon = $geo->lon;          #isa Float in radians

=cut

sub h3ToGeoWrapper {
  my $self  = shift;
  my $index = shift;
  my $geo   = $self->geo; #isa Geo::H3::FFI::Struct::GeoCoord
  $self->h3ToGeo($index, $geo);
  return $geo;
}

=head2 h3ToGeoBoundary

Finds the boundary of the index.

  my $gb        = $gh3->gb;           #isa empty Geo::H3::FFI::Struct::GeoBoundary
  $gh3->h3ToGeoBoundary($index, $gb); #populates $gb
  my $num_verts = $gb->num_verts;     #isa Int
  my $vert0     = $gb->verts->[0];    #isa Geo::H3::FFI::Struct::GeoCord

=cut

#void h3ToGeoBoundary(H3Index h3, GeoBoundary *gp);
$ffi->attach(h3ToGeoBoundary => ['uint64_t', 'geo_boundary_t'] => 'void' => \&_oowrapper);

=head2 h3ToGeoBoundaryWrapper

  my $GeoBoundary = $gh3->h3ToGeoBoundaryWrapper($index); #isa Geo::H3::FFI::Struct::GeoBoundary

=cut

sub h3ToGeoBoundaryWrapper {
  my $self  = shift;
  my $index = shift;
  my $gb    = $self->gb;
  $self->h3ToGeoBoundary($index, $gb);
  return $gb;
}

=head1 Index Inspection Functions

These functions provide metadata about an H3 index, such as its resolution or base cell, and provide utilities for converting into and out of the 64-bit representation of an H3 index.

=head2 h3GetResolution

Returns the resolution of the index.

  my $resolution = $gh3->h3GetResolution($index); #isa Int

=cut

#int h3GetResolution(H3Index h);
$ffi->attach(h3GetResolution => ['uint64_t'] => 'int' => \&_oowrapper);

=head2 h3GetBaseCell

Returns the base cell number of the index.

  my $baseCell = h3GetBaseCell($index);

=cut

#int h3GetBaseCell(H3Index h);
$ffi->attach(h3GetBaseCell => ['uint64_t'] => 'int' => \&_oowrapper);

=head2 stringToH3

Converts the string representation to H3Index (uint64_t) representation.

Returns 0 on error.

  my $index  = $gh3->stringToH3($string, length($string));

=cut

#H3Index stringToH3(const char *str);
$ffi->attach(stringToH3 => ['string', 'size_t'] => 'uint64_t' => \&_oowrapper);

=head2 stringToH3Wrapper

  my $index = $gh3->stringToH3Wrapper($string);

=cut

sub stringToH3Wrapper {
  my $self   = shift;
  my $string = shift;
  my $index  = $self->stringToH3($string, length($string));
  return $index;
}

=head2 h3ToString

Converts the H3Index representation of the index to the string representation. str must be at least of length 17.

  my $size   = 17; #Must be 17 for API to work
  my $string = "\000" x $size;
  $gh3->h3ToString($index, $string, $size);
  $string    =~ s/\000+\Z//;

=cut

#void h3ToString(H3Index h, char *str, size_t sz);
$ffi->attach(h3ToString => ['uint64_t', 'string', 'size_t'] => 'void' => \&_oowrapper);

=head2 h3ToStringWrapper

  my $string = $gh3->h3ToStringWrapper($index);

=cut

sub h3ToStringWrapper {
  my $self   = shift;
  my $index  = shift;
  my $size   = 17; #Must be 17 for API to work
  my $string = "\000" x $size;
  $self->h3ToString($index, $string, $size);
  $string    =~ s/\000+\Z//;
  return $string;
}

=head2 h3IsValid

Returns non-zero if this is a valid H3 index.

  my isValid = $gh3->h3IsValid($index);

=cut

#int h3IsValid(H3Index h);
$ffi->attach(h3IsValid => ['uint64_t'] => 'int' => \&_oowrapper);

=head2 h3IsResClassIII

Returns non-zero if this index has a resolution with Class III orientation.

  my $isRC3 = $gh3->h3IsResClassIII($index);

=cut

#int h3IsResClassIII(H3Index h);
$ffi->attach(h3IsResClassIII => ['uint64_t'] => 'int' => \&_oowrapper);

=head2 h3IsPentagon

Returns non-zero if this index represents a pentagonal cell.

  my $isPentagon = $gh3->h3IsPentagon($index);

=cut

#int h3IsPentagon(H3Index h);
$ffi->attach(h3IsPentagon => ['uint64_t'] => 'int' => \&_oowrapper);

=head2 h3GetFaces

Find all icosahedron faces intersected by a given H3 index and places them in the array out. out must be at least of length maxFaceCount(h).

Faces are represented as integers from 0-19, inclusive. The array is sparse, and empty (no intersection) array values are represented by -1.
 
  my @array = (-1,-1,-1,-1,-1);
  $gh3->h3GetFaces($index, \@array); #sets values into initialized array

=cut

#void h3GetFaces(H3Index h, int* out);
$ffi->attach(h3GetFaces => ['uint64_t', 'int_array'] => 'void' => \&_oowrapper);

=head2 h3GetFacesWrapper

  my $array_ref = $gh3->h3GetFacesWrapper($index);

=cut

sub h3GetFacesWrapper {
  my $self  = shift;
  my $index = shift;
  my $size  = $self->maxFaceCount($index);
  my @array = (-1) x $size;
  $self->h3GetFaces($index, \@array);
  return [grep {$_ > -1} @array];
}

=head2 maxFaceCount

Returns the maximum number of icosahedron faces the given H3 index may intersect.

  my $count = $gh3->maxFaceCount($index);

=cut

#int maxFaceCount(H3Index h3);
$ffi->attach(maxFaceCount => ['uint64_t'] => 'int' => \&_oowrapper);

=head1 Grid traversal functions

Grid traversal allows finding cells in the vicinity of an origin cell, and determining how to traverse the grid from one cell to another.

=head2 kRing

k-rings produces indices within k distance of the origin index.

k-ring 0 is defined as the origin index, k-ring 1 is defined as k-ring 0 and all neighboring indices, and so on.

Output is placed in the provided array in no particular order. Elements of the output array may be left zero, as can happen when crossing a pentagon.

  my $size  = $gh3->maxKringSize($k);
  my @array = (-1) x $size;
  $self->kRing($index, $k, \@array);

=cut

#void kRing(H3Index origin, int k, H3Index* out);
$ffi->attach(kRing => ['uint64_t', 'int', 'uint64_t_array'] => 'void' => \&_oowrapper);

=head2 kRingWrapper

Returns an array reference of H3 indices with the k distance of the origin index.

  my $aref = $gh3->kRingWrapper($index, $k); #ias ARRAY of H3 Indexes

=cut

sub kRingWrapper {
  my $self  = shift;
  my $index = shift;
  my $k     = shift;
  my $size  = $self->maxKringSize($k);
  my @array = (-1) x $size;
  $self->kRing($index, $k, \@array);
  return [grep {$_ > 0 && $_ < 18446744073709551615} @array];
}

=head2 maxKringSize

Maximum number of indices that result from the kRing algorithm with the given k.

  my $size  = $gh3->maxKringSize($k);

=cut

#int maxKringSize(int k);
$ffi->attach(maxKringSize => ['int'] => 'int' => \&_oowrapper);

=head2 kRingDistances

k-rings produces indices within k distance of the origin index.

k-ring 0 is defined as the origin index, k-ring 1 is defined as k-ring 0 and all neighboring indices, and so on.

Output is placed in the provided array in no particular order. Elements of the output array may be left zero, as can happen when crossing a pentagon.

  my $size  = $gh3->maxKringSize($k);
  my @array = (-1) x $size;
  my @dist  = (-1) x $size;
  my %hash  = ();
  $gh3->kRingDistances($index, $k, \@array, \@dist);

=cut

#void kRingDistances(H3Index origin, int k, H3Index* out, int* distances);
$ffi->attach(kRingDistances => ['uint64_t', 'int', 'uint64_t_array', 'int_array'] => 'void' => \&_oowrapper);

=head2 kRingDistancesWrapper

Returns a hash reference where the keys are the H3 index and values are the k distance for the given index and k value.

  my $href = $gh3->kRingDistancesWrapper($index, $k); #isa HASH

=cut

sub kRingDistancesWrapper {
  my $self  = shift;
  my $index = shift;
  my $k     = shift;
  my $size  = $self->maxKringSize($k);
  my @array = (-1) x $size;
  my @dist  = (-1) x $size;
  my %hash  = ();
  $self->kRingDistances($index, $k, \@array, \@dist);
  @hash{@array} = @dist; #hash slice assignment
  delete $hash{'18446744073709551615'};
  return \%hash;
}

=head2 hexRange

hexRange produces indexes within k distance of the origin index. Output behavior is undefined when one of the indexes returned by this function is a pentagon or is in the pentagon distortion area.

k-ring 0 is defined as the origin index, k-ring 1 is defined as k-ring 0 and all neighboring indexes, and so on.

Output is placed in the provided array in order of increasing distance from the origin.

Returns 0 if no pentagonal distortion is encountered.

  my $distortion = $gh3->hexRange($index, $k, \@out);

=cut

#int hexRange(H3Index origin, int k, H3Index* out);
$ffi->attach(hexRange => ['uint64_t', 'int', 'uint64_t_array'] => 'int' => \&_oowrapper);

=head2 hexRangeWrapper

  my @indexes = $gh3->hexRangeWrapper($index, $k);

=cut

sub hexRangeWrapper {
  my $self       = shift;
  my $index      = shift;
  my $k          = shift;
  my $size       = $self->maxHexRangeSize($k);
  my @array      = (-1) x $size;
  my $distortion = $self->hexRange($index, $k, \@array); #0 if no pentagonal distortion is encountered
  warn("Error: Package: $PACKAGE, Method: hexRangeWrapper, Distrortion: $distortion") if $distortion;
  return \@array;
}

=head2 maxHexRangeSize

  my $size = $gh3->maxHexRangeSize($k);

=cut

sub maxHexRangeSize {shift->maxKringSize(@_)};

=head2 hexRangeDistances

hexRange produces indexes within k distance of the origin index. Output behavior is undefined when one of the indexes returned by this function is a pentagon or is in the pentagon distortion area.

k-ring 0 is defined as the origin index, k-ring 1 is defined as k-ring 0 and all neighboring indexes, and so on.

Output is placed in the provided array in order of increasing distance from the origin. The distances in hexagons is placed in the distances array at the same offset.

Returns 0 if no pentagonal distortion is encountered.

  my $distortion = $gh3->hexRangeDistances($index, $k, \@indexes, \@distances);

=cut

#int hexRangeDistances(H3Index origin, int k, H3Index* out, int* distances);
$ffi->attach(hexRangeDistances => ['uint64_t', 'int', 'uint64_t_array', 'int_array'] => 'int' => \&_oowrapper);

=head2 hexRangeDistancesWrapper

 my $href = $gh3->hexRangeDistancesWrapper($index, $k); 

=cut

sub hexRangeDistancesWrapper {
  my $self       = shift;
  my $index      = shift;
  my $k          = shift;
  my $size       = $self->maxHexRangeSize($k);
  my @array      = (-1) x $size;
  my @dist       = (-1) x $size;
  my %hash       = ();
  my $distortion = $self->hexRangeDistances($index, $k, \@array, \@dist);
  warn("Error: Package: $PACKAGE, Method: hexRangeDistancesWrapper, Distrortion: $distortion") if $distortion;
  @hash{@array}  = @dist; #hash slice assignment
  delete $hash{'18446744073709551615'};
  return \%hash;
}

=head2 hexRanges

hexRanges takes an array of input hex IDs and a max k-ring and returns an array of hexagon IDs sorted first by the original hex IDs and then by the k-ring (0 to max), with no guaranteed sorting within each k-ring group.

Returns 0 if no pentagonal distortion was encountered. Otherwise, output is undefined

=cut

#int hexRanges(H3Index* h3Set, int length, int k, H3Index* out);
$ffi->attach(hexRanges => ['uint64_t_array', 'int', 'int', 'uint64_t_array'] => 'int' => \&_oowrapper);

=head2 hexRing

Produces the hollow hexagonal ring centered at origin with sides of length k.

Returns 0 if no pentagonal distortion was encountered.

  my $distortion = $gh3->hexRing($index, $k, \@ring);

=cut

#int hexRing(H3Index origin, int k, H3Index* out);
$ffi->attach(hexRing => ['uint64_t', 'int', 'uint64_t_array'] => 'int' => \&_oowrapper);

=head2 hexRingWrapper

  my $aref = $gh3->hexRingWrapper($index, $k);

=cut

sub hexRingWrapper {
  my $self       = shift;
  my $index      = shift;
  my $k          = shift;
  my $size       = $self->maxHexRingSize($k);
  my @array      = (-1) x $size;
  my $distortion = $self->hexRing($index, $k, \@array); #0 if no pentagonal distortion was encountered
  warn("Error: Package: $PACKAGE, Method: hexRingWrapper, Distrortion: $distortion") if $distortion;
  return [grep {$_ > 0 and $_ < 18446744073709551615} @array];
}

=head2 maxHexRingSize

  my $size = $gh3->maxHexRingSize($k);

=cut

sub maxHexRingSize {
  my $self = shift;
  my $k    = shift;
  return $k == 0 ? 1 : $k * 6; #See: https://www.rubydoc.info/gems/h3/3.2.0/H3%2FTraversal:max_hex_ring_size
}

=head2 h3Line

Given two H3 indexes, return the line of indexes between them (inclusive).

This function may fail to find the line between two indexes, for example if they are very far apart. It may also fail when finding distances for indexes on opposite sides of a pentagon.

Notes:

 - The specific output of this function should not be considered stable across library versions. The only guarantees the library provides are that the line length will be h3Distance(start, end) + 1 and that every index in the line will be a neighbor of the preceding index.

 - Lines are drawn in grid space, and may not correspond exactly to either Cartesian lines or great arcs.

=cut

#int h3Line(H3Index start, H3Index end, H3Index* out);
$ffi->attach(h3Line => ['uint64_t', 'uint64_t', 'uint64_t_array'] => 'int' => \&_oowrapper);

=head2 h3LineWrapper

  my $aref = $gh3->h3LineWrapper($start, $end);

=cut

sub h3LineWrapper {
  my $self  = shift;
  my $start = shift;
  my $end   = shift;
  my $size  = $self->h3LineSize($start, $end);
  my @array = (-1) x $size;
  my $int   = $self->h3Line($start, $end, \@array); #what is int???
  return \@array;
}

=head2 h3LineSize

Number of indexes in a line from the start index to the end index, to be used for allocating memory. Returns a negative number if the line cannot be computed.

=cut

#int h3LineSize(H3Index start, H3Index end);
$ffi->attach(h3LineSize => ['uint64_t', 'uint64_t'] => 'int' => \&_oowrapper);

=head2 h3Distance

Returns the distance in grid cells between the two indexes.

Returns a negative number if finding the distance failed. Finding the distance can fail because the two indexes are not comparable (different resolutions), too far apart, or are separated by pentagonal distortion. This is the same set of limitations as the local IJ coordinate space functions.

=cut

#int h3Distance(H3Index origin, H3Index h3);
$ffi->attach(h3Distance => ['uint64_t', 'uint64_t'] => 'int' => \&_oowrapper);

=head2 experimentalH3ToLocalIj

Produces local IJ coordinates for an H3 index anchored by an origin.

This function is experimental, and its output is not guaranteed to be compatible across different versions of H3.

=cut

#int experimentalH3ToLocalIj(H3Index origin, H3Index h3, CoordIJ *out);


=head2 experimentalLocalIjToH3

Produces an H3 index from local IJ coordinates anchored by an origin.

This function is experimental, and its output is not guaranteed to be compatible across different versions of H3.

=cut

#int experimentalLocalIjToH3(H3Index origin, const CoordIJ *ij, H3Index *out);

=head1 Hierarchical grid functions

These functions permit moving between resolutions in the H3 grid system. The functions produce parent (coarser) or children (finer) cells.

=head2 h3ToParent

Returns the parent (coarser) index containing h.

  my $parent = $gh3->h3ToParent($index, $resolution);

=cut

#H3Index h3ToParent(H3Index h, int parentRes);
$ffi->attach(h3ToParent => ['uint64_t', 'int'] => 'uint64_t' => \&_oowrapper);

=head2 h3ToChildren

Populates children with the indexes contained by h at resolution childRes. children must be an array of at least size maxH3ToChildrenSize(h, childRes).

  my $size  = $gh3->maxH3ToChildrenSize($index, $res);
  my @array = (-1) x $size;
  $gh3->h3ToChildren($index, $res, \@array);

=cut

#void h3ToChildren(H3Index h, int childRes, H3Index *children);
$ffi->attach(h3ToChildren => ['uint64_t', 'int', 'uint64_t_array'] => 'void' => \&_oowrapper);

=head2 h3ToChildrenWrapper

  my $aref = $gh3->h3ToChildrenWrapper($index, $resoultion);

=cut

sub h3ToChildrenWrapper {
  my $self  = shift;
  my $index = shift;
  my $res   = shift;
  my $size  = $self->maxH3ToChildrenSize($index, $res);
  my @array = (-1) x $size;
  $self->h3ToChildren($index, $res, \@array);
  return \@array;
}

=head2 maxH3ToChildrenSize

  my $size  = $gh3->maxH3ToChildrenSize($index, $res);

=cut

#int maxH3ToChildrenSize(H3Index h, int childRes);
$ffi->attach(maxH3ToChildrenSize => ['uint64_t', 'int'] => 'int' => \&_oowrapper);

=head2 h3ToCenterChild

Returns the center child (finer) index contained by h at resolution childRes.

=cut

#H3Index h3ToCenterChild(H3Index h, int childRes);
$ffi->attach(h3ToCenterChild => ['uint64_t', 'int'] => 'uint64_t' => \&_oowrapper);

=head2 compact

Compacts the set h3Set of indexes as best as possible, into the array compactedSet. compactedSet must be at least the size of h3Set in case the set cannot be compacted.

Returns 0 on success.

=cut

#int compact(const H3Index *h3Set, H3Index *compactedSet, const int numHexes);
$ffi->attach(compact => ['uint64_t_array', 'uint64_t_array', 'int'] => 'int' => \&_oowrapper);

=head2 compactWrapper

  my $aref = $gh3->compactWrapper(\@indexes);

=cut

sub compactWrapper {
  my $self  = shift;
  my $in    = shift;
  my $out   = [map {-1} @$in];
  my $size  = scalar(@$in);
  my $error = $self->compact($in, $out, $size);
  die(qq{Error: Package $PACKAGE method compact returned error code "$error"}) if $error;
  return [grep {$_ > 0 and $_ < 18446744073709551615} @$out];
}

=head2 uncompact

Uncompacts the set compactedSet of indexes to the resolution res. h3Set must be at least of size maxUncompactSize(compactedSet, numHexes, res).

Returns 0 on success.

=cut

#int uncompact(const H3Index *compactedSet, const int numHexes, H3Index *h3Set, const int maxHexes, const int res);
$ffi->attach(uncompact => ['uint64_t_array', 'int', 'uint64_t_array', 'int', 'int'] => 'int' => \&_oowrapper);

=head2 uncompactWrapper

  my $aref = $gh3->uncompactWrapper(\@indexes, $resolution);

=cut

sub uncompactWrapper {
  my $self       = shift;
  my $in         = shift;
  my $resolution = shift || 0;
  my $size       = $self->maxUncompactSize($in, scalar(@$in), $resolution);
  my $out        = [(-1) x $size];
  my $error      = $self->uncompact($in, scalar(@$in), $out, scalar(@$out), $resolution);
  die(qq{Error: Package $PACKAGE method uncompact returned error code "$error"}) if $error;
  return [grep {$_ > -1} @$out];
}

=head2 maxUncompactSize

Returns the size of the array needed by uncompact.

=cut

#int maxUncompactSize(const H3Index *compactedSet, const int numHexes, const int res)
$ffi->attach(maxUncompactSize => ['uint64_t_array', 'int', 'int'] => 'int' => \&_oowrapper);

=head1 Region functions

These functions convert H3 indexes to and from polygonal areas.

=head2 polyfill

polyfill takes a given GeoJSON-like data structure and preallocated, zeroed memory, and fills it with the hexagons that are contained by the GeoJSON-like data structure.

Containment is determined by the cells' centroids. A partioning using the GeoJSON-like data structure, where polygons cover an area without overlap, will result in a partitioning in the H3 grid, where cells cover the same area without overlap.

=cut

#void polyfill(const GeoPolygon* geoPolygon, int res, H3Index* out);

=head2 maxPolyfillSize

maxPolyfillSize returns the number of hexagons to allocate space for when performing a polyfill on the given GeoJSON-like data structure.

=cut

#int maxPolyfillSize(const GeoPolygon* geoPolygon, int res);

=head2 h3SetToLinkedGeo

Create a LinkedGeoPolygon describing the outline(s) of a set of hexagons. Polygon outlines will follow GeoJSON MultiPolygon order: Each polygon will have one outer loop, which is first in the list, followed by any holes.

It is the responsibility of the caller to call destroyLinkedPolygon on the populated linked geo structure, or the memory for that structure will not be freed.

It is expected that all hexagons in the set have the same resolution and that the set contains no duplicates. Behavior is undefined if duplicates or multiple resolutions are present, and the algorithm may produce unexpected or invalid output.

=cut

#void h3SetToLinkedGeo(const H3Index* h3Set, const int numHexes, LinkedGeoPolygon* out);

=head2 h3SetToMultiPolygon

=cut

#void h3SetToMultiPolygon(const H3Index* h3Set, const int numHexes, MultiPolygon* out);

=head2 destroyLinkedPolygon

Free all allocated memory for a linked geo structure. The caller is responsible for freeing memory allocated to the input polygon struct.

=cut

=head1 Unidirectional edge functions

Unidirectional edges allow encoding the directed edge from one cell to a neighboring cell.

=head2 h3IndexesAreNeighbors

Returns whether or not the provided H3Indexes are neighbors.

Returns 1 if the indexes are neighbors, 0 otherwise.

=cut

#int h3IndexesAreNeighbors(H3Index origin, H3Index destination);
$ffi->attach(h3IndexesAreNeighbors => ['uint64_t', 'uint64_t'] => 'int' => \&_oowrapper);

=head2 getH3UnidirectionalEdge

Returns a unidirectional edge H3 index based on the provided origin and destination.

Returns 0 on error.

=cut

#H3Index getH3UnidirectionalEdge(H3Index origin, H3Index destination);
$ffi->attach(getH3UnidirectionalEdge => ['uint64_t', 'uint64_t'] => 'uint64_t' => \&_oowrapper);

=head2 h3UnidirectionalEdgeIsValid

Determines if the provided H3Index is a valid unidirectional edge index.

Returns 1 if it is a unidirectional edge H3Index, otherwise 0.

=cut

#int h3UnidirectionalEdgeIsValid(H3Index edge);
$ffi->attach(h3UnidirectionalEdgeIsValid => ['uint64_t'] => 'int' => \&_oowrapper);

=head2 getOriginH3IndexFromUnidirectionalEdge

Returns the origin hexagon from the unidirectional edge H3Index.

=cut

#H3Index getOriginH3IndexFromUnidirectionalEdge(H3Index edge);
$ffi->attach(getOriginH3IndexFromUnidirectionalEdge => ['uint64_t'] => 'uint64_t' => \&_oowrapper);

=head2 getDestinationH3IndexFromUnidirectionalEdge

Returns the destination hexagon from the unidirectional edge H3Index.

=cut

#H3Index getDestinationH3IndexFromUnidirectionalEdge(H3Index edge);
$ffi->attach(getDestinationH3IndexFromUnidirectionalEdge => ['uint64_t'] => 'uint64_t' => \&_oowrapper);

=head2 getH3IndexesFromUnidirectionalEdge

Returns the origin, destination pair of hexagon IDs for the given edge ID, which are placed at originDestination[0] and originDestination[1] respectively.

=cut

#void getH3IndexesFromUnidirectionalEdge(H3Index edge, H3Index* originDestination);

=head2 getH3UnidirectionalEdgesFromHexagon

Provides all of the unidirectional edges from the current H3Index. edges must be of length 6, and the number of undirectional edges placed in the array may be less than 6.

=cut

#void getH3UnidirectionalEdgesFromHexagon(H3Index origin, H3Index* edges);

=head2 getH3UnidirectionalEdgeBoundary

Provides the coordinates defining the unidirectional edge.

=cut

#void getH3UnidirectionalEdgeBoundary(H3Index edge, GeoBoundary* gb);
$ffi->attach(getH3UnidirectionalEdgeBoundary => ['uint64_t', 'geo_boundary_t'] => 'void' => \&_oowrapper);

=head1 Miscellaneous H3 functions

These functions include descriptions of the H3 grid system.

=head2 degsToRads

Converts degrees to radians.

=cut

#double degsToRads(double degrees);
$ffi->attach(degsToRads => ['double'] => 'double' => \&_oowrapper);

=head2 radsToDegs

Converts radians to degrees.

=cut

#double radsToDegs(double radians);
$ffi->attach(radsToDegs => ['double'] => 'double' => \&_oowrapper);

=head2 hexAreaKm2

Average hexagon area in square kilometers at the given resolution.

=cut

#double hexAreaKm2(int res);
$ffi->attach(hexAreaKm2 => ['int'] => 'double' => \&_oowrapper);

=head2 hexAreaM2

Average hexagon area in square meters at the given resolution.

=cut

#double hexAreaM2(int res);
$ffi->attach(hexAreaM2 => ['int'] => 'double' => \&_oowrapper);

=head2 cellAreaM2

Exact area of specific cell in square meters.

=cut

#double cellAreaM2(H3Index h);
$ffi->attach(cellAreaM2 => ['uint64_t'] => 'double' => \&_oowrapper);

=head2 cellAreaRads2

Exact area of specific cell in square radians.

=cut

#double cellAreaRads2(H3Index h);
$ffi->attach(cellAreaRads2 => ['uint64_t'] => 'double' => \&_oowrapper);

=head2 edgeLengthKm

Average hexagon edge length in kilometers at the given resolution.

=cut

#double edgeLengthKm(int res);
$ffi->attach(edgeLengthKm=> ['int'] => 'double' => \&_oowrapper);

=head2 edgeLengthM

Average hexagon edge length in meters at the given resolution.

=cut

#double edgeLengthM(int res);
$ffi->attach(edgeLengthM=> ['int'] => 'double' => \&_oowrapper);

=head2 exactEdgeLengthKm

Exact edge length of specific unidirectional edge in kilometers.

=cut

#double exactEdgeLengthKm(H3Index edge);
$ffi->attach(exactEdgeLengthKm=> ['uint64_t'] => 'double' => \&_oowrapper);

=head2 exactEdgeLengthM

Exact edge length of specific unidirectional edge in meters.

=cut

#double exactEdgeLengthM(H3Index edge);
$ffi->attach(exactEdgeLengthM => ['uint64_t'] => 'double' => \&_oowrapper);

=head2 exactEdgeLengthRads

Exact edge length of specific unidirectional edge in radians.

=cut

#double exactEdgeLengthRads(H3Index edge);
$ffi->attach(exactEdgeLengthRads => ['uint64_t'] => 'double' => \&_oowrapper);

=head2 numHexagons

Number of unique H3 indexes at the given resolution.

=cut

#int64_t numHexagons(int res);
$ffi->attach(numHexagons => ['int'] => 'int64_t' => \&_oowrapper);

=head2 getRes0Indexes

All the resolution 0 H3 indexes. out must be an array of at least size res0IndexCount().

=cut

#void getRes0Indexes(H3Index *out);

=head2 res0IndexCount

Number of resolution 0 H3 indexes.

=cut

#int res0IndexCount();
$ffi->attach(res0IndexCount => [] => 'int' => \&_oowrapper);

=head2 getPentagonIndexes

All the pentagon H3 indexes at the specified resolution. out must be an array of at least size pentagonIndexCount().

=cut

#void getPentagonIndexes(int res, H3Index *out);

=head2 pentagonIndexCount

Number of pentagon H3 indexes per resolution. This is always 12, but provided as a convenience.

=cut

#int pentagonIndexCount();
$ffi->attach(pentagonIndexCount => [] => 'int' => \&_oowrapper);

=head2 pointDistKm

Gives the "great circle" or "haversine" distance between pairs of GeoCoord points (lat/lon pairs) in kilometers.

=cut

#double pointDistKm(const GeoCoord *a, const GeoCoord *b);
$ffi->attach(pointDistKm => ['geo_coord_t', 'geo_coord_t'] => 'double' => \&_oowrapper);

=head2 pointDistM

Gives the "great circle" or "haversine" distance between pairs of GeoCoord points (lat/lon pairs) in meters.

=cut

#double pointDistM(const GeoCoord *a, const GeoCoord *b);
$ffi->attach(pointDistM => ['geo_coord_t', 'geo_coord_t'] => 'double' => \&_oowrapper);


=head2 pointDistRads

Gives the "great circle" or "haversine" distance between pairs of GeoCoord points (lat/lon pairs) in radians.

=cut

#double pointDistRads(const GeoCoord *a, const GeoCoord *b);
$ffi->attach(pointDistRads => ['geo_coord_t', 'geo_coord_t'] => 'double' => \&_oowrapper);


=head1 SEE ALSO

L<https://h3geo.org/docs/api/indexing>, L<https://h3geo.org/docs/community/bindings>, L<FFI::CheckLib>, L<FFI::Platypus>, L<FFI::C>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2020 Michael R. Davis

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

# File: lib/Geo/H3.pm

## NAME

Geo::H3 - H3 Geospatial Hexagon Indexing System

## SYNOPSIS

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
    

## DESCRIPTION

This Perl distribution provides a Perl Object Oriented interface to the H3 Core Library.  It accesses the H3 C library using [libffi](https://github.com/libffi/libffi) and [FFI::Platypus](https://metacpan.org/pod/FFI%3A%3APlatypus).

H3 is a geospatial indexing system that partitions the world into hexagonal cells. Please note that a very few number of cells are pentagons but we use the terms hex or hexagon to include pentagons.

The H3 Core Library implements the H3 grid system. It includes functions for converting from latitude and longitude coordinates to the containing H3 cell, finding the center of H3 cells, finding the boundary geometry of H3 cells, finding neighbors of H3 cells, and more.

The H3 Core Library can be installed from Uber's H3 repository on GitHub [https://github.com/uber/h3](https://github.com/uber/h3) which is well documented at [https://h3geo.org/docs/](https://h3geo.org/docs/).  

### CONVENTIONS

The Geo::H3 lib is an Object Oriented wrapper on top of the [Geo::H3::FFI](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AFFI) library.  Geo::H3 was written as a wrapper so that in the future we are able to re-write against different backends such as the yet to be developed Geo::H3::XS backend.

#### libh3

    - Latitude and longitude cordinates are in radians WGS-84
    - H3 Index values are handled as uint64 integers
    - GeoCoord values are handled as C structures with lat and lon
    - GeoBoundary values are handled as C structures with num_verts and verts

#### Geo::H3::FFI

    - Latitude and Longitude cordinates are in radians WGS-84
    - H3 Index values are handled as uint64 integers
    - GeoCoord values are handled as Geo::H3::FFI::Struct::GeoCoord objects
    - GeoBoundary values are handled as Geo::H3::FFI::Struct::GeoBoundary objects

#### Geo::H3

    - Latitude and longitue cordinates are in decimal degrees WGS-84
    - H3 Index values are handled as Geo::H3::Index objects
    - GeoCoord values are handled as Geo::H3::GeoCoord objects
    - GeoBoundary values are handled as Geo::H3::GeoBoundary objects

## CONSTRUCTORS

### h3

Returns a [Geo::H3::Index](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AIndex) object

    my $hex = $gh3->h3(unit64 => $int);                  #isa Geo::H3::Index
    my $hex = $gh3->h3(string => $string);               #isa Geo::H3::Index
    my $hex = Geo::H3::Index->new(uint64 => $h3_uint64); #isa Geo::H3::Index
    my $hex = Geo::H3::Index->new(string => $h3_string); #isa Geo::H3::Index

### geo

Returns a [Geo::H3::Geo](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AGeo) object

    my $geo = $gh3->geo(lat=>$lat_deg, lon=>$lon_deg);         #isa Geo::H3::Geo
    my $geo = Geo::H3::Geo->new(lat=>$lat_deg, lon=>$lon_deg); #isa Geo::H3::Geo

### ffi

Returns the [Geo::H3::FFI](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AFFI) object.

## LIMITATIONS

This package uses the naming convention of version 3.x of the Uber H3 library.  The organization that maintains the open source Uber H3 library has not maintained backward compatibility in version 4.x.  This Perl distribution currently sees no reason to support the 4.x version of the Uber H3 library as the 3.7.2 release is stable and full featured.

## SEE ALSO

[https://h3geo.org/docs/3.x/](https://h3geo.org/docs/3.x/), [https://github.com/uber/h3/tree/stable-3.x](https://github.com/uber/h3/tree/stable-3.x), [Geo::H3::FFI](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AFFI)

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2021 Michael R. Davis

# File: lib/Geo/H3/Index.pm

## NAME

Geo::H3::Index - H3 Geospatial Hexagon Indexing System Index Object

## SYNOPSIS

    use Geo::H3::Index;
    my $h3       = Geo::H3::Index->new(string => $string); #isa Geo::H3::Index
    my $center   = $h3->geo;                             #isa Geo::H3::Geo
    my $lat      = $center->lat;                         #isa double WGS-84 Decimal Degrees
    my $lon      = $center->lon;                         #isa double WGS-84 Decimal Degrees
    my $boundary = $h3->geoBoundary;                     #isa Geo::H3::GeoBoundary

## DESCRIPTION

H3 Geospatial Hexagon Indexing System Index Object provides the primary interface for working with H3 Indexes.

## CONSTRUCTORS

### new

    my $h3 = Geo::H3::Index->new(string=>$string);
    my $h3 = Geo::H3::Index->new(uint64=>$uint64);

## PROPERTIES

### string

Returns the H3 string representation.

### uint64

Returns the H3 uint64 representation.

### index (DEPRECATED)

Returns the H3 uint64 representation.

Please note that \`index()\` was difficult to remember consistently.  Therefore, I plan to move to the \`uint64()\` property moving forward while maintaining backwards compatibility.

### resolution

Returns the resolution of the hex.

### baseCell

Returns the base cell number of the hex.

### isValid

Returns non-zero if this is a valid H3 hex.

### isResClassIII

Returns non-zero if this hex has a resolution with Class III orientation.

### isPentagon

Returns non-zero if this hex represents a pentagonal cell.

### maxFaceCount

Returns the maximum number of icosahedron faces the given H3 hex may intersect.

### area

Returns the area in square meters of this hex.

### areaApprox

Returns the average area in square meters of hexes at this resolution.

### edgeLength

Returns the exact edge length in meters that this hex shares with the passed in neighbor.

    my $edgeLength_meters = $hex->edgeLength(); #default hex is first kring neighbor
    my $edgeLength_meters = $hex->edgeLength($neighbor_hex_obj);

### edgeLengthAverage

Returns the average of the exact edge lengths in meters of this hex. 

### edgeLengthApprox

Returns the average edge length in meters of hexes at this resolution.

## METHODS

### geo

Returns the centroid of the hex as a [Geo::H3::Geo](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AGeo) object.

### geoBoundary

Returns the boundary of the hex as a [Geo::H3::GeoBoundary](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AGeoBoundary) object

### parent

Returns a parent hex of this hex as a [Geo::H3::Index](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AIndex) object.

    my $parent = $h3->parent;    #next larger resolution
    my $parent = $h3->parent(1); #isa Geo::H3::Index

### children

Returns the children of the hex as an array reference of [Geo::H3::Index](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AIndex) objects.

    my $children = $h3->children(12); #isa ARRAY
    my $children = $h3->children;     #next smaller resolution

### centerChild

Returns the center child (finer) hex contained by this hex at given resolution.

    my $centerChild = $hex->centerChild;      #isa Geo::H3::Index
    my $centerChild = $hex->centerChild(12);  #isa Geo::H3::Index

### kRing

Returns k-rings hexes within k distance of the origin hex.

    my $hexes_aref = $hex->kRing($k); #isa ARRAY of L<Geo::H3::Index> objects

### kRingDistances

Returns a hash reference where the keys are the H3 hex and values are the k distance for the given hex and k value.

    my $distances_aref = $hex->kRingDistances($k); #isa ARRAY-ARRAY [ [$hex1, $dist1], [$hex2, $dist2], ... [$hexN, $distN] ]

### hexRange

Returns an array reference of hexes within k distance of the hex object. k-ring 0 is defined as the origin index, k-ring 1 is defined as k-ring 0 and all neighboring indexes, and so on.

    my $hexes_aref = $hex->hexRange($k);

### hexRangeDistances

Returns a hash reference where the keys are the H3 uint64 and values are the k distance for the given hex and k value.

    my $hash = $hex->hexRangeDistances($k); #isa ARRAY-ARRAY [ [$hex1, $dist1], [$hex2, $dist2], ... [$hexN, $distN] ]

### hexRing

Returns the hex ring of this hex as an array reference of [Geo::H3::Index](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AIndex) objects

    my $hexes = $h3->hexRing; #default k = 1
    my $hexes = $h3->hexRing(5); #isa ARRAY

### areNeighbors

Returns a 1 or 0 based on whether or not the provided hex object is a neighbor.

    my $areNeighbors = $start_hex->areNeighbors($end_hex);

### line

Returns the hexes starting at this hex to the given end hex as array reference of [Geo::H3::Index](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AIndex) objects.

    my $list_aref = $start_hex_obj->line($end_hex_obj);

### distance

Returns the distance in grid cells between this hex to the given end hex.

    my $distance = $start_hex_obj->distance($end_hex_obj);

## SEE ALSO

[Geo::H3](https://metacpan.org/pod/Geo%3A%3AH3), [Geo::H3::FFI](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AFFI)

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2021 Michael R. Davis

# File: lib/Geo/H3/Geo.pm

## NAME

Geo::H3::Geo - H3 Geospatial Hexagon Indexing System Geo Object

## SYNOPSIS

    use Geo::H3::Geo;
    my $geo    = Geo::H3::Geo->new(lat=>$lat, lon=>$lon); #isa Geo::H3::Geo
    my $h3     = $geo->h3($resolution);                   #isa Geo::H3::Index
    my $center = $h3->geo;                                #isa Geo::H3::Geo
    my $lat    = $center->lat;                            #isa double WGS-84 Decimal Degrees
    my $lon    = $center->lon;                            #isa double WGS-84 Decimal Degrees

## DESCRIPTION

H3 Geospatial Hexagon Indexing System Geo Object exposes the lat and lon properties as WGS-84 Decimal Degrees and converts coordinates to radians in the struct method for passing into the[Geo::H3::FFI](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AFFI) API as a [Geo::H3::FFI::Struct::GeoCoord](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AFFI%3A%3AStruct%3A%3AGeoCoord) object.

The methods h3 and distance are wrappers around select [Geo::H3::FFI](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AFFI) methods.

## CONSTRUCTORS

### new

    my $geo = Geo::H3::Geo->new(lat => $lat, lon => $lon);

## PROPERTIES

### lat

Returns the latitude in decimal degrees WGS-84

### lon

Returns the longitude in decimal degrees WGS-84

## METHODS

### struct

Returns the Geo object as an [FFI::C](https://metacpan.org/pod/FFI%3A%3AC) struct in the [Geo::H3::FFI::Struct::GeoCoord](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AFFI%3A%3AStruct%3A%3AGeoCoord) namespace for use in the [Geo::H3::FFI](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AFFI) API.

### h3

Indexes the location at the specified resolution, returning the hex object [Geo::H3::Index](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AIndex) of the cell containing the location.

    my $h3 = $geo->h3;    #default resolution is 0
    my $h3 = $geo->h3(7); #isa Geo::H3::H3Index

Returns undef on error.

### distance

Returns in meters the "great circle" or "haversine" distance between pairs of points (lat/lon pairs).

    my $distance = $geoA->distance($geoB); #isa Double

## SEE ALSO

[Geo::H3](https://metacpan.org/pod/Geo%3A%3AH3), [Geo::H3::FFI](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AFFI), [Geo::H3::Index](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AIndex), [Geo::H3::FFI::Struct::GeoCoord](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AFFI%3A%3AStruct%3A%3AGeoCoord)

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2021 Michael R. Davis

# File: lib/Geo/H3/GeoBoundary.pm

## NAME

Geo::H3::GeoBoundary - H3 Geospatial Hexagon Indexing System GeoBoundary Object

## SYNOPSIS

    use Geo::H3::GeoBoundary;
    my $GeoBoundary = Geo::H3::GeoBoundary->new(gb=>$gb);            #isa Geo::H3::GeoBoundary
    my $GeoBoundary = Geo::H3::GeoBoundary->new(gb=>$gb, ffi=>$ffi); #isa Geo::H3::GeoBoundary

## DESCRIPTION

H3 Geospatial Hexagon Indexing System GeoBoundary Object provides coordinates method to extract data from the FFI GeoBoundary object

## CONSTRUCTORS

### new

    my $GeoBoundary = Geo::H3::GeoBoundary->new(gb=>$gb);

## PROPERTIES

### gb

Returns the H3 GeoBoundary Object from the API as a [Geo::H3::FFI::Struct::GeoBoundary](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AFFI%3A%3AStruct%3A%3AGeoBoundary) object

    my $struct = $GeoBoundary->gb; #isa Geo::H3::FFI::Struct::GeoBoundary

## METHODS

### coordinates

Returns an OGC compatible closed polygon as an array reference of hashes i.e. \[{lat=>$lat, lon=>$lon}, ...\].

This coordinates format plugs directly into the format required for many [Geo::GoogleEarth::Pluggable](https://metacpan.org/pod/Geo%3A%3AGoogleEarth%3A%3APluggable) objects.

## SEE ALSO

[Geo::H3](https://metacpan.org/pod/Geo%3A%3AH3), [Geo::H3::FFI::Struct::GeoBoundary](https://metacpan.org/pod/Geo%3A%3AH3%3A%3AFFI%3A%3AStruct%3A%3AGeoBoundary), [Geo::GoogleEarth::Pluggable](https://metacpan.org/pod/Geo%3A%3AGoogleEarth%3A%3APluggable)

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2021 Michael R. Davis

# File: scripts/perl-Geo-H3-geo-to-googleearth.pl

## NAME

perl-Geo-H3-geo-to-googleearth.pl - Creates a Google Earth document from Coordinates, H3, Parent, Children and Hex Ring.

## SYNTAX

    perl-Geo-H3-geo-to-googleearth.pl --lat=[degrees] --lon=[degrees] --resolution=[hex_resolution] --output=[output_filename]

## EXAMPLES

Default creates output.kmz

    $ perl-Geo-H3-geo-to-googleearth.pl
    Lat: 38.8894806546995
    Lon: -77.0352387595358
    Resolution: 8
    Output: output.kmz
    Format: kmz

KMZ output with defaults specified

    $ perl-Geo-H3-geo-to-googleearth.pl --lat=38.889480654699476 --lon=-77.03523875953579 --resolution=8 --output=output.kmz
    Lat: 38.889480654699476
    Lon: -77.03523875953579
    Resolution: 8
    Output: output.kmz
    Format: kmz

KML output pass a file name with "kml" extension.

    $ perl-Geo-H3-geo-to-googleearth.pl --output=output.kml
    Lat: 38.8894806546995
    Lon: -77.0352387595358
    Resolution: 8
    Output: output.kml
    Format: kml

## SEE ALSO

[Geo::GoogleEarth::Pluggable](https://metacpan.org/pod/Geo%3A%3AGoogleEarth%3A%3APluggable), [Geo::GoogleEarth::Pluggable::Plugin::Styles](https://metacpan.org/pod/Geo%3A%3AGoogleEarth%3A%3APluggable%3A%3APlugin%3A%3AStyles), [Path::Class](https://metacpan.org/pod/Path%3A%3AClass)

## COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2026 Michael R. Davis


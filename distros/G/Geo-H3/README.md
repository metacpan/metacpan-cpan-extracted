# File: lib/Geo/H3.pm

## NAME

Geo::H3 - H3 Geospatial Hexagon Indexing System

## SYNOPSIS

    use Geo::H3;
    my $gh3      = Geo::H3->new;
    
    my $h3       = $gh3->h3(index  => $int);        #isa Geo::H3::Index
    my $h3       = $gh3->h3(string => $string);     #isa Geo::H3::Index

    my $geo      = $gh3->geo(lat=>$lat, lon=>$lon); #isa Geo::H3::Geo
    my $h3       = $geo->h3($resolution);           #isa Geo::H3::Index

    my $center   = $h3->center;                     #isa Geo::H3::GeoCoord
    my $lat      = $center->lat;                    #isa Double WGS-84 Decimal Degrees
    my $lon      = $center->lon;                    #isa Double WGS-84 Decimal Degrees
    my $distance = $center->distance($geo);         #isa Double meters
    

## DESCRIPTION

This Perl distribution provides a Perl Object Oriented interface to the H3 Core Library.  It accesses the H3 C library using [libffi](https://github.com/libffi/libffi) and [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus).

H3 is a geospatial indexing system that partitions the world into hexagonal cells.

The H3 Core Library implements the H3 grid system. It includes functions for converting from latitude and longitude coordinates to the containing H3 cell, finding the center of H3 cells, finding the boundary geometry of H3 cells, finding neighbors of H3 cells, and more.

The H3 Core Library can be installed from Uber's H3 repository on GitHub [https://github.com/uber/h3](https://github.com/uber/h3) which is well documented at [https://h3geo.org/docs/](https://h3geo.org/docs/).  

### CONVENTIONS

The Geo::H3 lib is an Object Oriented wrapper on top of the [Geo::H3::FFI](https://metacpan.org/pod/Geo::H3::FFI) library.  Geo::H3 was written as a wrapper so that in the future we are able to re-write against different backends such as the yet to be developed Geo::H3::XS backend.

#### libh3

    - Latitude and longitue cordinates are in radians WGS-84
    - H3 Index values are handled as uint64 integers
    - GeoCoord values are handled as C structures with lat and lon
    - GeoBoundary values are handled as C structures with num_verts and verts

#### Geo::H3::FFI

    - Latitude and Longitue cordinates are in radians WGS-84
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

Returns a [Geo::H3::Index](https://metacpan.org/pod/Geo::H3::Index) object

    my $h3 = $gh3->h3(index  => $int);             #isa Geo::H3::Index
    my $h3 = $gh3->h3(string => $string);          #isa Geo::H3::Index
    my $h3 = Geo::H3::Index->new(index => $index); #isa Geo::H3::Index

### geo

Returns a [Geo::H3::Geo](https://metacpan.org/pod/Geo::H3::Geo) object

    my $geo = $gh3->geo(lat=>$lat_deg, lon=>$lon_deg);         #isa Geo::H3::Geo
    my $geo = Geo::H3::Geo->new(lat=>$lat_deg, lon=>$lon_deg); #isa Geo::H3::Geo

## SEE ALSO

[https://h3geo.org/](https://h3geo.org/), [https://github.com/uber/h3/](https://github.com/uber/h3/), [Geo::H3::FFI](https://metacpan.org/pod/Geo::H3::FFI)

## INSTALLATION

[Geo::H3](https://metacpan.org/pod/Geo::H3) has some pretty deep requirements that are not available in many OS repositories.  For RedHat and CentOS 7 users, I have have built RPMs and placed them on my [Linux Yum Repository](http://linux.davisnetworks.com/el7/)

To install the distribution with all dependencies - CentOS 7

    $ sudo yum install http://linux.davisnetworks.com/el7/updates/mrdvt92-release-8-2.el7.mrdvt92.noarch.rpm
    $ sudo yum install 'perl(Geo::H3)'

To install the additional dependencies for the example script perl-Geo-H3-geo-to-googleearth.pl

    $ sudo yum install 'perl(Geo::GoogleEarth::Pluggable)' 'perl(Geo::GoogleEarth::Pluggable::Plugin::Styles)' 'perl(Path::Class)'

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

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

# File: lib/Geo/H3/Index.pm

## NAME

Geo::H3::Index - H3 Geospatial Hexagon Indexing System Index Object

## SYNOPSIS

    use Geo::H3::Index;
    my $h3     = Geo::H3::Index->new(index=$index); #isa Geo::H3::Index
    my $center = $h3->geo;                          #isa Geo::H3::GeoCoord
    my $lat    = $center->lat;                      #isa double WGS-84 Decimal Degrees
    my $lon    = $center->lon;                      #isa double WGS-84 Decimal Degrees

## DESCRIPTION

H3 Geospatial Hexagon Indexing System Index Object provides the primary interface for working with H3 Indexes.

## CONSTRUCTORS

### new

    my $geo = Geo::H3::Index->new(index=>$index);

## PROPERTIES

### index

Returns the H3 index uint64 representation

### string

Returns the H3 string representation.

### resolution

Returns the resolution of the index.

### baseCell

Returns the base cell number of the index.

### isValid

Returns non-zero if this is a valid H3 index.

### isResClassIII

Returns non-zero if this index has a resolution with Class III orientation.

### isPentagon

Returns non-zero if this index represents a pentagonal cell.

### maxFaceCount

Returns the maximum number of icosahedron faces the given H3 index may intersect.

### area

Returns the area in square meters of this index.

### areaApprox

Returns the average area in square meters of indexes at this resolution.

### edgeLength

Returns the exact edge length in meters of this index.

### edgeLengthApprox

Returns the average edge length in meters of indexes at this resolution.

## METHODS

### geo

Returns the centroid of the index as a [Geo::H3::Geo](https://metacpan.org/pod/Geo::H3::Geo) object.

### geoBoundary

Returns the boundary of the index as a [Geo::H3::GeoBoundary](https://metacpan.org/pod/Geo::H3::GeoBoundary) object

### parent

Returns a parent index of this index as a [Geo::H3::Index](https://metacpan.org/pod/Geo::H3::Index) object.

    my $parent = $h3->parent;    #next larger resolution
    my $parent = $h3->parent(1); #isa Geo::H3::Index

### children

Returns the children of the index as an array reference of [Geo::H3::Index](https://metacpan.org/pod/Geo::H3::Index) objects.

    my $children = $h3->children(12); #isa ARRAY
    my $children = $h3->children;     #next smaller resolution

### centerChild

Returns the center child (finer) index contained by this index at given resolution.

    my $centerChild = $index->centerChild;      #isa Geo::H3::Index
    my $centerChild = $index->centerChild(12);  #isa Geo::H3::Index

### kRing

Returns k-rings indexes within k distance of the origin index.

    my $list $index->kRing($k); #isa ARRAY of L<Geo::H3::Index> objects

### kRingDistances

Returns a hash reference where the keys are the H3 index and values are the k distance for the given index and k value.

    my $hash = $index->kRingDistances($k);

### hexRange

    my $indexes = $index->hexRange($k);

### hexRangeDistances

Returns a hash reference where the keys are the H3 index and values are the k distance for the given index and k value.

    my $hash = $index->hexRangeDistances($k);

### hexRing

Returns the hex ring of this index as an array reference of [Geo::H3::Index](https://metacpan.org/pod/Geo::H3::Index) objects

    my $hexes = $h3->hexRing; #default k = 1
    my $hexes = $h3->hexRing(5); #isa ARRAY

### areNeighbors

Returns whether or not the provided H3Indexes are neighbors.

    my $areNeighbors = $start_index->areNeighbors($end_index);

### line

Returns the indexes starting at this index to the given end index as array reference of [Geo::H3::Index](https://metacpan.org/pod/Geo::H3::Index) objects.

    my $list_aref = $start_index->line($end_index);

### distance

Returns the distance in grid cells between this index to the given end index.

    my $distance = $start_index->distance($end_index);

## SEE ALSO

[Geo::H3](https://metacpan.org/pod/Geo::H3), [Geo::H3::FFI](https://metacpan.org/pod/Geo::H3::FFI)

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

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

# File: lib/Geo/H3/Geo.pm

## NAME

Geo::H3::Geo - H3 Geospatial Hexagon Indexing System Geo Object

## SYNOPSIS

    use Geo::H3::Geo;
    my $geo    = Geo::H3::Geo->new(lat=>$lat, lon=>$lon); #isa Geo::H3::Geo
    my $h3     = $geo->h3($resolution);                   #isa Geo::H3::Index
    my $center = $h3->center;                             #isa Geo::H3::Geo
    my $lat    = $center->lat;                            #isa double WGS-84 Decimal Degrees
    my $lon    = $center->lon;                            #isa double WGS-84 Decimal Degrees

## DESCRIPTION

H3 Geospatial Hexagon Indexing System Geo Object exposes the lat and lon properties as WGS-84 Decimal Degrees and converts coordinates to radians in the struct method for passing into the[Geo::H3::FFI](https://metacpan.org/pod/Geo::H3::FFI) API as a [Geo::H3::FFI::Struct::GeoCoord](https://metacpan.org/pod/Geo::H3::FFI::Struct::GeoCoord) object.

The methods h3 and distance are wrappers around select [Geo::H3::FFI](https://metacpan.org/pod/Geo::H3::FFI) methods.

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

Returns the Geo object as an [FFI::C](https://metacpan.org/pod/FFI::C) struct in the [Geo::H3::FFI::Struct::GeoCoord](https://metacpan.org/pod/Geo::H3::FFI::Struct::GeoCoord) namespace for use in the [Geo::H3::FFI](https://metacpan.org/pod/Geo::H3::FFI) API.

### h3

Indexes the location at the specified resolution, returning the index object [Geo::H3::Index](https://metacpan.org/pod/Geo::H3::Index) of the cell containing the location.

    my $h3 = $geo->h3;    #default resolution is 0
    my $h3 = $geo->h3(7); #isa Geo::H3::H3Index

Returns undef on error.

### distance

Returns in meters the "great circle" or "haversine" distance between pairs of points (lat/lon pairs).

    my $distance = $geoA->distance($geoB); #isa Double

## SEE ALSO

[Geo::H3](https://metacpan.org/pod/Geo::H3), [Geo::H3::FFI](https://metacpan.org/pod/Geo::H3::FFI), [Geo::H3::Index](https://metacpan.org/pod/Geo::H3::Index), [Geo::H3::FFI::Struct::GeoCoord](https://metacpan.org/pod/Geo::H3::FFI::Struct::GeoCoord)

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

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

# File: lib/Geo/H3/GeoBoundary.pm

## NAME

Geo::H3::GeoBoundary - H3 Geospatial Hexagon Indexing System GeoBoundary Object

## SYNOPSIS

    use Geo::H3::GeoBoundary;
    my $gb = Geo::H3::GeoBoundary->new(gb=>$gb); #isa Geo::H3::GeoBoundary
    my $gb = Geo::H3::GeoBoundary->new(gb=>$gb, ffi=>$ffi); #isa Geo::H3::GeoBoundary

## DESCRIPTION

H3 Geospatial Hexagon Indexing System GeoBoundary Object provides coordinates method to extract data from the FFI GeoBoundary object

## CONSTRUCTORS

### new

    my $geo = Geo::H3::GeoBoundary->new(gb=>$gb);

## PROPERTIES

### gb

Returns the H3 GeoBoundary Object from the API as a [Geo::H3::FFI::Struct::GeoBoundary](https://metacpan.org/pod/Geo::H3::FFI::Struct::GeoBoundary) object

## METHODS

### coordinates

Returns an OGC compatible closed polygon as an array reference of hashes i.e. \[{lat=>$lat, lon=>$lon}, ...\].

This coordinates format plugs directly into the format required for many [Geo::GoogleEarth::Pluggable](https://metacpan.org/pod/Geo::GoogleEarth::Pluggable) objects.

## SEE ALSO

[Geo::H3](https://metacpan.org/pod/Geo::H3), [Geo::H3::FFI::Struct::GeoBoundary](https://metacpan.org/pod/Geo::H3::FFI::Struct::GeoBoundary), [Geo::GoogleEarth::Pluggable](https://metacpan.org/pod/Geo::GoogleEarth::Pluggable)

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

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

# File: scripts/perl-Geo-H3-geo-to-googleearth.pl

## NAME

perl-Geo-H3-geo-to-googleearth.pl - Creates a Google Earth document from Coordinates, H3, Parent, Children and Hex Ring.

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

[Geo::GoogleEarth::Pluggable](https://metacpan.org/pod/Geo::GoogleEarth::Pluggable), [Geo::GoogleEarth::Pluggable::Plugin::Styles](https://metacpan.org/pod/Geo::GoogleEarth::Pluggable::Plugin::Styles), [Path::Class](https://metacpan.org/pod/Path::Class)

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

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


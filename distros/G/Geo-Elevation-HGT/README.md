# Name

Geo::Elevation::HGT - Elevation service with terrain data provided by [Mapzen and Amazon AWS S3](https://registry.opendata.aws/terrain-tiles/)

# Version

Version 0.01

# Synopsis

    use Geo::Elevation::HGT;
    my ($lat, $lon) = (45.8325, 6.86444444444444);    # MontBlanc
    my $geh = Geo::Elevation::HGT->new();
    print $geh->get_elevation_hgt ($lat, $lon)."\n";
    # 4790.99999999998

# Description

This module implements an elevation service with terrain data provided by [Mapzen and Amazon AWS S3](https://registry.opendata.aws/terrain-tiles/).

You provide the latitude and longitude in decimal degrees, with south latitude and west longitude being negative.

The return is the elevation for this latitude and longitude in meters.
Bilinear interpolation is applied to the elevations at the four grid points adjacent to the latitude plus longitude pair.

You can also use your own terrain tiles by providing the corresponding path, see below.
A good source for Europe that I am using was compiled by Sonny -- many thanks to him; found at [https://data.opendataportal.at/dataset/dtm-europe](https://data.opendataportal.at/dataset/dtm-europe)

In addition you can specify a cache folder for subsequent use of downloaded tiles, see below.

There are only core dependencies

    Carp
    IO::Uncompress::AnyUncompress
    HTTP::Tiny
    POSIX
    File::Find
    List::Util

# Notice

Geo::Elevation::HGT loads the required terrain tiles (from .HGT format files, see below) into the returned object, i.e. into memory.

Any following query requiring the same tile will be much faster since it only involves memory access, instead of a download from the internet.

In a typical application of getting elevations for a gpx track of an outdoor activity, all track points are normally on one tile, maybe two.

To get the elevations of a few thousand gpx track points is therefore normally quite fast.

Here is a benchmark I did on my 2015 NUC5i3RYK with Intel 5010U dual-core processor

\- 4.5 s for the first elevation with download of the terrain tile from Amazon AWS S3

\- 0.5 s for the first elevation with the terrain tile stored on my NAS

\- 50,000 elevations per second with the terrain tile in memory

It is the user's responsibility to respect the license and terms of use for the data provided by Mapzen and Amazon AWS S3.

# Example

Get elevation in meters of any latitude plus longitude pair by the 'get\_elevation\_hgt' method.

Pass latitude and longitude in decimal notation, i.e. 45.8325, 6.86444444444444 for MontBlanc.

    use Geo::Elevation::HGT;

    # Latitude, longitude, elevation of some famous mountains (Wikipedia)
    my @mountains = ( {Denali    => {lat =>   63+( 4*60+ 7)/3600,  lon => -(151+( 0*60+28)/3600), ele_wiki => 6190  } },
                      {Everest   => {lat =>   27+(59*60+16)/3600,  lon =>    86+(55*60+29)/3600 , ele_wiki => 8848  } },
                      {MontBlanc => {lat =>   45+(49*60+57)/3600,  lon =>     6+(51*60+52)/3600 , ele_wiki => 4810  } },
                      {Aconcagua => {lat => -(32+(39*60+13)/3600), lon =>  -(70+(00*60+40)/3600), ele_wiki => 6960.8} } );

    # Get elevations of these famous mountains
    my $geh = Geo::Elevation::HGT->new();
    for my $mountain ( @mountains ) {
      my ($name) = %$mountain;
      my ($lat, $lon, $ele_wiki) = ($mountain->{$name}{'lat'}, $mountain->{$name}{'lon'}, $mountain->{$name}{'ele_wiki'});
      my $ele_geh = $geh->get_elevation_hgt ($lat, $lon);
      print join( ' ', $name, $lat, $lon, $ele_wiki, $ele_geh, $ele_geh-$ele_wiki, "\n");
    }

    # returns
    # Denali 63.0686111111111 -151.007777777778 6190 6126.9999999999 -63.0000000000955
    # Everest 27.9877777777778 86.9247222222222 8848 8713.0000000001 -134.999999999898
    # MontBlanc 45.8325 6.86444444444444 4810 4791.00000000002 -18.9999999999764
    # Aconcagua -32.6536111111111 -70.0111111111111 6960.8 6923.00000000011 -37.7999999998856

The elevations returned for these famous mountains are lower than their effective ones since the underlying data, which originate from SRTM (Shuttle Radar Topography Mission) and other sources, smooth peaks and thereby show them lower than commonly known.

Nevertheless the elevations returned should be useful to obtain a good representation of the elevation profile of a gpx track.

According to my experience these are much better than elevations recorded by a gps logger on a mobile phone.
Such elevation data include a lot of noise with erratic jumps by 100 m.

# Methods

## new

`$geh = Geo::Elevation::HGT->new( %parameters )`

Constructor, returns a new Geo::Elevation::HGT object.

Valid parameters, all optional:

\* `folder` - the path to a folder where the terrain tiles to use are stored; no default

\* `url` - the url of the terrain tiles to use; default [https://elevation-tiles-prod.s3.amazonaws.com/skadi](https://elevation-tiles-prod.s3.amazonaws.com/skadi)

\* `cache_folder` path to an existing folder where the terrain tiles downloaded from `$geh->{url}` will be stored for subsequent use; no default

Note that cache will not expire and will have to be cleared from outside of `Geo::Elevation::HGT`. Thinking is that terrain data will not change very frequently.

\* `debug` - set to 1 to get some debug output to STDERR; default 0

## get\_elevation\_hgt

`$ele_geh = $geh->get_elevation_hgt ($lat, $lon)`

Arguments: latitude and longitude in decimal degrees, with south latitude and west longitude being negative

Returns the elevation for this latitude and longitude in meters

### Flags

\* `$geh->{switch}` - is set to 1 in case a required tile is not found under the `$geh->{folder}` path in which case the data source is switched to `$geh->{url}`; otherwise 0

\* `$geh->{cache}` - is set to 1 in case a required tile is used from `$geh->{cache_folder}`; otherwise 0

\* `$geh->{fail}` - is set to 1 in case access to a required tile under `$geh->{url}` fails in which case all corresponding elevations will be set to 0; otherwise 0.

### Status Description

\* `$geh->{status_descr}` - is set to a string describing how the terrain tile was found, using the following key words, or a combination thereof

\- `Memory` - the tile was in memory from a previous call

\- `Folder` - the user provided a valid folder path, if nothing follows the tile was found and used

\- `Switch` - the tile was not found under the `$geh->{folder}` path

\- `Cached` - the tile was found under the `$geh->{cache_folder}` path

\- `Url`    - the tile was downloaded from the C$geh->{url}> path, unless subsequent `Failed` indicates failure

\- `Failed` - access to the tile under `$geh->{url}` failed

\- `Saved`  - the downloaded tile was saved to cache under the `$geh->{cache_folder}` path

## get\_elevation\_batch\_hgt

`$ele_geh = $geh->get_elevation_batch_hgt ($latlon)`

Argument: an array reference with arrays of latitude-longitude pairs, i.e. `[[lat1, lon1], [lat2, lon2], ...]`

Returns an array reference with the associated elevations `[ele1, ele2, ...]`

Provided for user convenience. Calls method `get_elevation_hgt` in turn for every latitude-longitude pair.

Flags and Status Description reflect the state after the call with the last latitude-longitude pair.

# HGT DEM (digital elevation model) files

The names of individual DEM files refer to the latitude and longitude of the lower-left (south-west) corner of the tile.

e.g. N37W105 has its lower left corner at 37 degrees north latitude and 105 degrees west longitude.

The DEM is provided as 16-bit signed integer data in a simple binary raster.

There are no header or trailer bytes embedded in the file.

Each file is a series of signed 16-bit integers (two bytes) giving the height of each cell in meters arranged from west to east and then north to south.

Elevations are in meters referenced to the WGS84/EGM96 geoid.

Byte order is Motorola ("big-endian") standard with the most significant byte first.

Grid size is 3601x3601 for 1-minute DEMs or 1201x1201 for 3-minute DEMs.

The rows at the north and south edges as well as the columns at the east and west edges of each cell overlap and are identical to the edge rows and columns in the adjacent cell.

# HGT directory tree

[https://elevation-tiles-prod.s3.amazonaws.com/skadi](https://elevation-tiles-prod.s3.amazonaws.com/skadi) stores HGT files in subdirectories by their latitude

    ...
    ├── N45
    │   ├── N45E000.hgt.gz
    │   ├── N45E001.hgt.gz
    │   ├── N45E002.hgt.gz
    ...
    ├── N46
    │   ├── N46E000.hgt.gz
    │   ├── N46E001.hgt.gz
    │   ├── N46E002.hgt.gz
    ...
    ├── S46
    │   ├── S46W000.hgt.gz
    │   ├── S46W001.hgt.gz
    │   ├── S46W002.hgt.gz
    ...

`$geh->{folder}` will work without following the above storage pattern, as long as a file with the correct name is found somewhere under that path.

Similarly, `$geh->{cache}` will be built to the above storage pattern, but will also work if files are stored in any other way under that path.

HGT files need to be compressed to GNU zip (gzip) or ZIP (zip) compression format with .hgt.gz or .zip file extension, respectively.

# Author

Ulrich Buck, `<ulibuck at cpan.org>`

# Bugs

Please report any bugs or feature requests to `bug-geo-elevation-hgt at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Elevation-HGT](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Elevation-HGT).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# Support

You can find documentation for this module with the perldoc command.

    perldoc Geo::Elevation::HGT

You can also look for information at:

    -- Note: not found on CPAN (yet) -- check again later --

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Elevation-HGT](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Elevation-HGT)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Geo-Elevation-HGT](http://annocpan.org/dist/Geo-Elevation-HGT)

- CPAN Ratings

    [https://cpanratings.perl.org/d/Geo-Elevation-HGT](https://cpanratings.perl.org/d/Geo-Elevation-HGT)

- Search CPAN

    [https://metacpan.org/release/Geo-Elevation-HGT](https://metacpan.org/release/Geo-Elevation-HGT)

# Acknowledgements

Inspired by

[racemap Elevation service](https://github.com/racemap/elevation-service)

[Using DEMs to get GPX elevation profiles](http://notes.secretsauce.net/notes/2014/03/18_using-dems-to-get-gpx-elevation-profiles.html)

plus others

# License and Copyright

This software is Copyright (c) 2020 by Ulrich Buck.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

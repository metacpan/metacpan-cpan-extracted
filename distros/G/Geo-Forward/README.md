# NAME

Geo::Forward - Calculate geographic location from latitude, longitude, distance, and heading.

# SYNOPSIS

    use Geo::Forward;
    my $gf                         = Geo::Forward->new(); # default "WGS84"
    my ($lat1, $lon1, $faz, $dist) = (38.871022, -77.055874, 62.888507083, 4565.6854);
    my ($lat2, $lon2, $baz)        = $gf->forward($lat1, $lon1, $faz, $dist);
    print "Input Lat: $lat1  Lon: $lon1\n";
    print "Input Forward Azimuth: $faz (degrees)\n";
    print "Input Distance: $dist (meters)\n";
    print "Output Lat: $lat2 Lon: $lon2\n";
    print "Output Back Azimuth: $baz (degreees)\n";

# DESCRIPTION

This module is a pure Perl port of the NGS program in the public domain "forward" by Robert (Sid) Safford and Stephen J. Frakes.

# CONSTRUCTOR

## new

The new() constructor may be called with any parameter that is appropriate to the ellipsoid method which establishes the ellipsoid.

    my $gf = Geo::Forward->new(); # default "WGS84"

# METHODS

## initialize

## ellipsoid

Method to set or retrieve the current ellipsoid object.  The ellipsoid is a [Geo::Ellipsoids](https://metacpan.org/pod/Geo::Ellipsoids) object.

    my $ellipsoid = $gf->ellipsoid;  #Default is WGS84

    $gf->ellipsoid('Clarke 1866'); #Built in ellipsoids from Geo::Ellipsoids
    $gf->ellipsoid({a=>1});        #Custom Sphere 1 unit radius

## forward

This method is the user frontend to the mathematics. This interface will not change in future versions.

    my ($lat2, $lon2, $baz) = $gf->forward($lat1, $lon1, $faz, $dist);

Note: Latitude and longitude units are signed decimal degrees.   The distance units are based on the ellipsoid semi-major axis which is meters for WGS-84.  The forward and backward azimuths units are signed degrees clockwise from North.

## bbox

Returns a hash reference for the bounding box around a point with the given radius.

    my $bbox = $gf->bbox($lat, $lon, $radius); #isa HASH {north=>$north, east=>$east, south=>$south, west=>$west}

    Note: This is not an optimised solution input is welcome

    UOM: radius units of semi-major axis (default meters for WGS-84)

# BUGS

Please open an issue on GitHub

# LIMITS

No guarantees that Perl handles all of the double precision calculations in the same manner as Fortran.

# LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis

# SEE ALSO

### Similar Packages

[Geo::Distance](https://metacpan.org/pod/Geo::Distance), [Geo::Ellipsoid](https://metacpan.org/pod/Geo::Ellipsoid), [Geo::Calc](https://metacpan.org/pod/Geo::Calc)

## Opposite Package

[Geo::Inverse](https://metacpan.org/pod/Geo::Inverse)

## Building Blocks

[Geo::Ellipsoids](https://metacpan.org/pod/Geo::Ellipsoids), [Geo::Constants](https://metacpan.org/pod/Geo::Constants), [Geo::Functions](https://metacpan.org/pod/Geo::Functions)

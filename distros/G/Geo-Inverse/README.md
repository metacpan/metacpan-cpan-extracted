# NAME

Geo::Inverse - Calculate geographic distance from a latitude and longitude pair

# SYNOPSIS

    use Geo::Inverse;
    my $obj                         = Geo::Inverse->new();                    #default "WGS84"
    my ($lat1, $lon1, $lat2, $lon2) = (38.87, -77.05, 38.95, -77.23);
    my ($faz, $baz, $dist)          = $obj->inverse($lat1,$lon1,$lat2,$lon2); #array context
    my $dist=$obj->inverse($lat1, $lon1, $lat2, $lon2);                       #scalar context
    print "Input Lat: $lat1 Lon: $lon1\n";
    print "Input Lat: $lat2 Lon: $lon2\n";
    print "Output Distance: $dist\n";
    print "Output Forward Azimuth: $faz\n";
    print "Output Back Azimuth: $baz\n";

# DESCRIPTION

This module is a pure Perl port of the NGS program in the public domain "inverse" by Robert (Sid) Safford and Stephen J. Frakes.  

# CONSTRUCTOR

## new

The new() constructor may be called with any parameter that is appropriate to the ellipsoid method which establishes the ellipsoid.

    my $obj = Geo::Inverse->new(); # default "WGS84"

# METHODS

## initialize

## ellipsoid

Method to set or retrieve the current ellipsoid object.  The ellipsoid is a Geo::Ellipsoids object.

    my $ellipsoid = $obj->ellipsoid;  #Default is WGS84

    $obj->ellipsoid('Clarke 1866'); #Built in ellipsoids from Geo::Ellipsoids
    $obj->ellipsoid({a=>1});        #Custom Sphere 1 unit radius

## inverse

This method is the user frontend to the mathematics. This interface will not change in future versions.

    my ($faz, $baz, $dist) = $obj->inverse($lat1,$lon1,$lat2,$lon2);

# BUGS

Please open an issue on GitHub

# LIMITS

No guarantees that Perl handles all of the double precision calculations in the same manner as Fortran.

# LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis

# SEE ALSO

[Geo::Ellipsoid](https://metacpan.org/pod/Geo::Ellipsoid), [GIS::Distance::GeoEllipsoid](https://metacpan.org/pod/GIS::Distance::GeoEllipsoid), [Geo::Calc](https://metacpan.org/pod/Geo::Calc)

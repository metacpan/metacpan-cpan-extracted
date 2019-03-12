# NAME

GIS::Distance::GeoEllipsoid - Geo::Ellipsoid distance calculations.

# SYNOPSIS

    # Use the default WGS84 ellipsoid:
    my $gis = GIS::Distance->new( 'GeoEllipsoid' );
    
    # Set to a custom ellipsoid:
    my $gis = GIS::Distance->new( 'GeoEllipsoid', 'NAD27' );

# DESCRIPTION

This module is a wrapper around [Geo::Ellipsoid](https://metacpan.org/pod/Geo::Ellipsoid) for [GIS::Distance](https://metacpan.org/pod/GIS::Distance).

Normally this module is not used directly.  Instead [GIS::Distance](https://metacpan.org/pod/GIS::Distance)
is used which in turn interfaces with the various formula modules.

# ARGUMENTS

An optional argument may be passed which must be, as shown in the
["SYNOPSIS"](#synopsis), an ellipsoid name as defined at
["DEFINED ELLIPSOIDS" in Geo::Ellipsoid](https://metacpan.org/pod/Geo::Ellipsoid#DEFINED-ELLIPSOIDS).

Otherwise the default, `WGS84`, will be used.

# FORMULA

This module is just a thin wrapper, so go see [Geo::Ellipsoid](https://metacpan.org/pod/Geo::Ellipsoid) for
details about how it works.

# SEE ALSO

[GIS::Distance](https://metacpan.org/pod/GIS::Distance)

[Geo::Ellipsoid](https://metacpan.org/pod/Geo::Ellipsoid)

# SUPPORT

Please submit bugs and feature requests to the GIS-Distance-GeoEllipsoid
GitHub issue tracker:

[https://github.com/bluefeet/GIS-Distance-GeoEllipsoid/issues](https://github.com/bluefeet/GIS-Distance-GeoEllipsoid/issues)

# AUTHORS

    Aran Clary Deltac <bluefeet@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

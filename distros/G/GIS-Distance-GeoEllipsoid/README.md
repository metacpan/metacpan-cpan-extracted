# NAME

GIS::Distance::GeoEllipsoid - Geo::Ellipsoid distance calculations.

# SYNOPSIS

```perl
# Use the default WGS84 ellipsoid:
my $gis = GIS::Distance->new( 'GeoEllipsoid' );

# Set the ellipsoid:
my $gis = GIS::Distance->new( 'GeoEllipsoid', 'NAD27' );
```

# DESCRIPTION

This module is a wrapper around [Geo::Ellipsoid](https://metacpan.org/pod/Geo::Ellipsoid) for [GIS::Distance](https://metacpan.org/pod/GIS::Distance).

Normally this module is not used directly.  Instead [GIS::Distance](https://metacpan.org/pod/GIS::Distance)
is used which in turn interfaces with the various formula classes.

# OPTIONAL ARGUMENTS

## ellipsoid

```perl
my $gis = GIS::Distance->new( 'GeoEllipsoid', 'NAD27' );
```

Pass the name of an ellipsoid, per ["DEFINED ELLIPSOIDS" in Geo::Ellipsoid](https://metacpan.org/pod/Geo::Ellipsoid#DEFINED-ELLIPSOIDS).

If not set the default ellipsoid, `WGS84`, will be used.

# SUPPORT

Please submit bugs and feature requests to the
GIS-Distance-GeoEllipsoid GitHub issue tracker:

[https://github.com/bluefeet/GIS-Distance-GeoEllipsoid/issues](https://github.com/bluefeet/GIS-Distance-GeoEllipsoid/issues)

# AUTHORS

```
Aran Clary Deltac <bluefeet@cpan.org>
```

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

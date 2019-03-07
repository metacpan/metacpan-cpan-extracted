# NAME

GIS::Distance - Calculate geographic distances.

# SYNOPSIS

    use GIS::Distance;
    
    # Use the GIS::Distance::Haversine formula by default:
    my $gis = GIS::Distance->new();
    
    # Or choose a different formula:
    my $gis = GIS::Distance->new( 'Polar' );
    
    my $distance = $gis->distance( $lat1,$lon1 => $lat2,$lon2 );
    
    print $distance->meters();

# DESCRIPTION

This module calculates distances between geographic points on, at the moment,
plant Earth.  Various formulas are available that provide different levels of
accuracy versus calculation speed tradeoffs.

# METHODS

## distance

    my $distance = $gis->distance( $lat1,$lon1 => $lat2,$lon2 );

Returns a [Class::Measure::Length](https://metacpan.org/pod/Class::Measure::Length) object for the distance between the
two degree lats/lons.

See ["distance\_km"](#distance_km) to return raw kilometers instead.

## distance\_km

This works just like ["distance"](#distance) but return a raw kilometer measurement.

# ATTRIBUTES

## formula

Returns the formula name which was passed as the first argument to `new()`.

The formula can be specified as a partial or full module name for that
formula.  For example, if the formula is set to `Haversine` as in:

    my $gis = GIS::Distance->new( 'Haversine' );

Then the following modules will be looked for in order:

    GIS::Distance::Fast::Haversine
    GIS::Distance::Haversine
    Haversine

Note that a `Fast::` version of the class will be looked for first.  By default
the `Fast::` versions of the formulas, written in C, are not available and the
pure perl ones will be used instead.  If you would like the `Fast::` formulas
then install [GIS::Distance::Fast](https://metacpan.org/pod/GIS::Distance::Fast) and they will be automatically used.

## args

Returns the formula arguments, an array ref, containing the rest of the
arguments passed to `new()`.  Most formulas do not take arguments.  If
they do it will be described in their respective documentation.

## module

Returns the fully qualified module name that ["formula"](#formula) resolved to.

# SEE ALSO

[GIS::Distance::Fast](https://metacpan.org/pod/GIS::Distance::Fast) - C implmentation of some of the formulas
shipped with GIS::Distance.  This greatly increases the speed at
which distance calculations can be made.

# FORMULAS

[GIS::Distance::Cosine](https://metacpan.org/pod/GIS::Distance::Cosine)

[GIS::Distance::GeoEllipsoid](https://metacpan.org/pod/GIS::Distance::GeoEllipsoid)

[GIS::Distance::GreatCircle](https://metacpan.org/pod/GIS::Distance::GreatCircle)

[GIS::Distance::Haversine](https://metacpan.org/pod/GIS::Distance::Haversine)

[GIS::Distance::MathTrig](https://metacpan.org/pod/GIS::Distance::MathTrig)

[GIS::Distance::Polar](https://metacpan.org/pod/GIS::Distance::Polar)

[GIS::Distance::Vincenty](https://metacpan.org/pod/GIS::Distance::Vincenty)

# TODO

- Create a GIS::Coord class that represents a geographic coordinate.  Then modify
this module to accept input as either lat/lon pairs, or as GIS::Coord objects.
- Create some sort of equivalent to [Geo::Distance](https://metacpan.org/pod/Geo::Distance)'s closest() method.
- Write a formula module called GIS::Distance::Geoid.  Some very useful info is
at [http://en.wikipedia.org/wiki/Geoid](http://en.wikipedia.org/wiki/Geoid).

# BUGS

See ["BROKEN" in GIS::Distance::Polar](https://metacpan.org/pod/GIS::Distance::Polar#BROKEN).

# SUPPORT

Please submit bugs and feature requests to the GIS-Distance GitHub issue tracker:

[https://github.com/bluefeet/GIS-Distance/issues](https://github.com/bluefeet/GIS-Distance/issues)

# AUTHORS

    Aran Clary Deltac <bluefeet@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

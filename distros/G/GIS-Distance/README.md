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
planet Earth.  Various ["FORMULAS"](#formulas) are available that provide different levels
of accuracy versus speed.

[GIS::Distance::Fast](https://metacpan.org/pod/GIS::Distance::Fast), a separate distribution, ships with C implmentations of
some of the formulas shipped with GIS::Distance.  If you're looking for speed
then install it and the ::Fast formulas will be automatically used by this module.

# METHODS

## distance

    my $distance = $gis->distance( $lat1,$lon1 => $lat2,$lon2 );

Returns a [Class::Measure::Length](https://metacpan.org/pod/Class::Measure::Length) object for the distance between the
two degree lats/lons.

See ["distance\_metal"](#distance_metal) to return raw kilometers instead.

## distance\_metal

This works just like ["distance"](#distance), but always returns raw kilometers, does no
argument checking and ignores any formula ["args"](#args).  Calling this gets you pretty
close to the fastest bare metal speed you can get.  The speed improvements of
calling this is noticeable over millions of iterations only and you've got to
decide if its worth the safety and features you are dropping.

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

You may disable the automatic use of the `Fast::` formulas by setting the
`GIS_DISTANCE_PP` environment variable.

## args

Returns the formula arguments, an array ref, containing the rest of the
arguments passed to `new()` (anything passed after the ["formula"](#formula)).
Most formulas do not take arguments.  If they do it will be described in
their respective documentation.

## module

Returns the fully qualified module name that ["formula"](#formula) resolved to.

# SPEED

Not that this module is slow, but if you're doing millions of distance
calculations you may find that adjusting your code a bit may make it
faster.  Here are some options.

Install [GIS::Distance::Fast](https://metacpan.org/pod/GIS::Distance::Fast).

Use ["distance\_metal"](#distance_metal) instead of ["distance"](#distance).

Call the undocumented `distance()` function that each formula module
has.  For example you could bypass this module entirely and just do:

    use GIS::Distance::Fast::Haversine;
    my $km = GIS::Distance::Fast::Haversine::distance( @coords );

The above would be the ultimate speed demon (as shown in benchmarking)
but throws away some flexibility and adds some foot-gun support.

# COORDINATES

When passing latitudinal and longitudinal coordinates to ["distance"](#distance)
they must always be in decimal degree format.  Here is some sample code
for converting from other formats to decimal:

    # DMS to Decimal
    my $decimal = $degrees + ($minutes/60) + ($seconds/3600);
    
    # Precision Six Integer to Decimal
    my $decimal = $integer * .000001;

If you want to convert from decimal radians to degrees you can use [Math::Trig](https://metacpan.org/pod/Math::Trig)'s
rad2deg function.

# FORMULAS

These formulas come with this distribution:

[GIS::Distance::ALT](https://metacpan.org/pod/GIS::Distance::ALT)

[GIS::Distance::Cosine](https://metacpan.org/pod/GIS::Distance::Cosine)

[GIS::Distance::GreatCircle](https://metacpan.org/pod/GIS::Distance::GreatCircle)

[GIS::Distance::Haversine](https://metacpan.org/pod/GIS::Distance::Haversine)

[GIS::Distance::MathTrig](https://metacpan.org/pod/GIS::Distance::MathTrig)

[GIS::Distance::Null](https://metacpan.org/pod/GIS::Distance::Null)

[GIS::Distance::Polar](https://metacpan.org/pod/GIS::Distance::Polar)

[GIS::Distance::Vincenty](https://metacpan.org/pod/GIS::Distance::Vincenty)

These formulas are available on CPAN:

[GIS::Distance::Fast::ALT](https://metacpan.org/pod/GIS::Distance::Fast::ALT)

[GIS::Distance::Fast::Cosine](https://metacpan.org/pod/GIS::Distance::Fast::Cosine)

[GIS::Distance::Fast::GreatCircle](https://metacpan.org/pod/GIS::Distance::Fast::GreatCircle)

[GIS::Distance::Fast::Haversine](https://metacpan.org/pod/GIS::Distance::Fast::Haversine)

[GIS::Distance::Fast::Polar](https://metacpan.org/pod/GIS::Distance::Fast::Polar)

[GIS::Distance::Fast::Vincenty](https://metacpan.org/pod/GIS::Distance::Fast::Vincenty)

[GIS::Distance::GeoEllipsoid](https://metacpan.org/pod/GIS::Distance::GeoEllipsoid)

# SEE ALSO

[GIS::Distance::Lite](https://metacpan.org/pod/GIS::Distance::Lite) was long ago forked from GIS::Distance and modified
to have less dependencies.  Since then GIS::Distance itself has become
tremendously lighter dep-wise, and is still maintained, I suggest you not
use GIS::Distance::Lite.

[Geo::Distance](https://metacpan.org/pod/Geo::Distance) has long been deprecated in favor of using this module.

[Geo::Distance::XS](https://metacpan.org/pod/Geo::Distance::XS) used to be used by [Geo::Distance](https://metacpan.org/pod/Geo::Distance) but no longer does.

[Geo::Inverse](https://metacpan.org/pod/Geo::Inverse) seems to do some distance calculation using [Geo::Ellipsoid](https://metacpan.org/pod/Geo::Ellipsoid)
but if you look at the source code it clearly states that the entire meat of
it is copied from Geo::Ellipsoid... so I'm not sure why it exists... just use
Geo::Ellipsoid or [GIS::Distance::GeoEllipsoid](https://metacpan.org/pod/GIS::Distance::GeoEllipsoid) which wraps Geo::Ellipsoid
into the GIS::Distance interface.

[Geo::Distance::Google](https://metacpan.org/pod/Geo::Distance::Google) looks pretty neat.

# TODO

- Create a GIS::Coord class that represents a geographic coordinate.  Then modify
this module to accept input as either lat/lon pairs, or as GIS::Coord objects.
This would make coordinate conversion as described in ["COORDINATES"](#coordinates) automatic.
Maybe use [Geo::Point](https://metacpan.org/pod/Geo::Point).
- Create some sort of equivalent to [Geo::Distance](https://metacpan.org/pod/Geo::Distance)'s closest() method.
- Write a formula module called GIS::Distance::Geoid.  Some very useful info is
at [http://en.wikipedia.org/wiki/Geoid](http://en.wikipedia.org/wiki/Geoid).
- Make [GIS::Distance::Google](https://metacpan.org/pod/GIS::Distance::Google) (or some such name) and wrap it around
[Geo::Distance::Google](https://metacpan.org/pod/Geo::Distance::Google) (most likely).
- Figure out why [GIS::Distance::Polar](https://metacpan.org/pod/GIS::Distance::Polar) has issues.

# SUPPORT

Please submit bugs and feature requests to the GIS-Distance GitHub issue tracker:

[https://github.com/bluefeet/GIS-Distance/issues](https://github.com/bluefeet/GIS-Distance/issues)

# AUTHORS

    Aran Clary Deltac <bluefeet@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

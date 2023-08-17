# NAME

GIS::Distance - Calculate geographic distances.

# SYNOPSIS

```perl
use GIS::Distance;

# Use the GIS::Distance::Haversine formula by default.
my $gis = GIS::Distance->new();

# Or choose a different formula.
my $gis = GIS::Distance->new( 'Polar' );

# Returns a Class::Measure object.
my $distance = $gis->distance( $lat1, $lon1, $lat2, $lon2 );

print $distance->meters();
```

# DESCRIPTION

This module calculates distances between geographic points on, at the moment,
planet Earth.  Various ["FORMULAS"](#formulas) are available that provide different levels
of accuracy versus speed.

[GIS::Distance::Fast](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AFast), a separate distribution, ships with C implementations of
some of the formulas shipped with GIS::Distance.  If you're looking for speed
then install it and the ::Fast formulas will be automatically used by this module.

# METHODS

## distance

```perl
my $distance = $gis->distance( $lat1, $lon1, $lat2, $lon2 );

my $point1 = Geo::Point->latlong( $lat1, $lon1 );
my $point2 = Geo::Point->latlong( $lat2, $lon2 );
my $distance = $gis->distance( $point1, $point2 );
```

Takes either two decimal latitude and longitude pairs, or two [Geo::Point](https://metacpan.org/pod/Geo%3A%3APoint)
objects.

Returns a [Class::Measure::Length](https://metacpan.org/pod/Class%3A%3AMeasure%3A%3ALength) object for the distance between the
two degree lats/lons.

See ["distance\_metal"](#distance_metal) for a faster, but less feature rich, method.

## distance\_metal

This works just like ["distance"](#distance) except for:

- Does not accept [Geo::Point](https://metacpan.org/pod/Geo%3A%3APoint) objects.  Only decimal latitude and longitude
pairs.
- Does not return a [Class::Measure](https://metacpan.org/pod/Class%3A%3AMeasure) object.  Instead kilometers are always
returned.
- Does no argument checking.
- Does not support formula arguments which are supported by at least the
[GIS::Distance::GeoEllipsoid](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AGeoEllipsoid) formula.

Calling this gets you pretty close to the fastest bare metal speed you can get.
The speed improvements of calling this is noticeable over hundreds of thousands of
iterations only and you've got to decide if its worth the safety and features
you are dropping.  Read more in the ["SPEED"](#speed) section.

# ARGUMENTS

```perl
my $gis = GIS::Distance->new( $formula );
```

When you call `new()` you may pass a partial or full formula class name as the
first argument.  The default is `Haversive`.

If you pass a partial name, as in:

```perl
my $gis = GIS::Distance->new( 'Haversine' );
```

Then the following modules will be looked for in order:

```
GIS::Distance::Fast::Haversine
GIS::Distance::Haversine
Haversine
```

Install [GIS::Distance::Fast](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AFast) to get access to the `Fast::` (XS) implementations
of the formula classes.

You may globally disable the automatic use of the `Fast::` formulas by setting
the `GIS_DISTANCE_PP` environment variable.  Although, its likely simpler to
just provide a full class name to get the same effect:

```perl
my $gis = GIS::Distance->new( 'GIS::Distance::Haversine' );
```

# SPEED

Not that this module is slow, but if you're doing millions of distance
calculations a second you may find that adjusting your code a bit may
make it faster.  Here are some options.

Install [GIS::Distance::Fast](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AFast) to get the XS variants for most of the
PP formulas.

Use ["distance\_metal"](#distance_metal) instead of ["distance"](#distance).

Call the undocumented `_distance()` function that each formula class
has.  For example you could bypass this module entirely and just do:

```perl
use GIS::Distance::Fast::Haversine;
my $km = GIS::Distance::Fast::Haversine::_distance( @coords );
```

The above would be the ultimate speed demon (as shown in benchmarking)
but throws away some flexibility and adds some foot-gun support.

Here's a benchmarks for these options:

```
2019-03-13T09:34:00Z
GIS::Distance 0.15
GIS::Distance::Fast 0.12
GIS::Distance::Fast::Haversine 0.12
GIS::Distance::Haversine 0.15
                                                             Rate
PP Haversine - GIS::Distance->distance                   123213/s
XS Haversine - GIS::Distance->distance                   196232/s
PP Haversine - GIS::Distance->distance_metal             356379/s
PP Haversine - GIS::Distance::Haversine::_distance       385208/s
XS Haversine - GIS::Distance->distance_metal             3205128/s
XS Haversine - GIS::Distance::Fast::Haversine::_distance 8620690/s
```

You can run your own benchmarks using the included `author/bench`
script.  The above results were produced with:

```
author/bench -f Haversine
```

The slowest result was about `125000/s`, or about `8ms` each call.
This could be a substantial burden in some contexts, such as live HTTP
responses to human users and running large batch jobs, to name just two.

In conclusion, if you can justify the speed gain, switching to
["distance\_metal"](#distance_metal) and installing [GIS::Distance::Fast](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AFast) looks to be an
ideal setup.

As always with performance and benchmarking, YMMV.

# COORDINATES

When passing latitudinal and longitudinal coordinates to ["distance"](#distance)
they must always be in decimal degree format.  Here is some sample code
for converting from other formats to decimal:

```perl
# DMS to Decimal
my $decimal = $degrees + ($minutes/60) + ($seconds/3600);

# Precision Six Integer to Decimal
my $decimal = $integer * .000001;
```

If you want to convert from decimal radians to degrees you can use [Math::Trig](https://metacpan.org/pod/Math%3A%3ATrig)'s
rad2deg function.

# FORMULAS

These formulas come bundled with this distribution:

- [GIS::Distance::ALT](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AALT)
- [GIS::Distance::Cosine](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3ACosine)
- [GIS::Distance::GreatCircle](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AGreatCircle)
- [GIS::Distance::Haversine](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AHaversine)
- [GIS::Distance::MathTrig](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AMathTrig)
- [GIS::Distance::Null](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3ANull)
- [GIS::Distance::Polar](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3APolar)
- [GIS::Distance::Vincenty](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AVincenty)

These formulas are available on CPAN:

- ["FORMULAS" in GIS::Distance::Fast](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AFast#FORMULAS)
- [GIS::Distance::GeoEllipsoid](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AGeoEllipsoid)

# AUTHORING

Take a look at [GIS::Distance::Formula](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AFormula) for instructions on authoring
new formula classes.

# SEE ALSO

- [Geo::Distance](https://metacpan.org/pod/Geo%3A%3ADistance) - Is deprecated in favor of using this module.
- [Geo::Distance::Google](https://metacpan.org/pod/Geo%3A%3ADistance%3A%3AGoogle) - While in the Geo::Distance namespace, this isn't
actually related to Geo::Distance at all.  Might be useful though.
- [GIS::Distance::Lite](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3ALite) - An old fork of this module, not recommended.
- [Geo::Distance::XS](https://metacpan.org/pod/Geo%3A%3ADistance%3A%3AXS) - Used to be used by [Geo::Distance](https://metacpan.org/pod/Geo%3A%3ADistance) but no longer is.
- [Geo::Ellipsoid](https://metacpan.org/pod/Geo%3A%3AEllipsoid) - Or use [GIS::Distance::GeoEllipsoid](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AGeoEllipsoid) for a uniform
interface.
- [Geo::Inverse](https://metacpan.org/pod/Geo%3A%3AInverse) - Does some distance calculations, but seems less than useful
as all the code looks to be taken from [Geo::Ellipsoid](https://metacpan.org/pod/Geo%3A%3AEllipsoid).

# SUPPORT

Please submit bugs and feature requests to the
GIS-Distance GitHub issue tracker:

[https://github.com/bluefeet/GIS-Distance/issues](https://github.com/bluefeet/GIS-Distance/issues)

# AUTHOR

```
Aran Clary Deltac <bluefeet@gmail.com>
```

# CONTRIBUTORS

```
Mohammad S Anwar <mohammad.anwar@yahoo.com>
Florian Schlichting <fsfs@debian.org>
```

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

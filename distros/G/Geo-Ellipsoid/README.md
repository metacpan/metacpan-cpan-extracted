# NAME

Geo::Ellipsoid - longitude and latitude calculations using an ellipsoid model

# VERSION

Version 1.15.

# SYNOPSIS

    use Geo::Ellipsoid;

    my $geo = Geo::Ellipsoid->new(ellipsoid  => 'NAD27',
                                  angle_unit => 'degrees');

    my @origin = ( 37.619002, -122.374843 );      # SFO
    my @dest   = ( 33.942536, -118.408074 );      # LAX

    # range and bearing from one location to another

    my ( $range, $bearing ) = $geo->to( @origin, @dest );
    $range = $geo->range( @origin, @dest );
    $bearing = $geo->bearing( @origin, @dest );

    # destination given start point, range, and bearing

    my ( $lat, $lon ) = $geo->at( @origin, 2000, 45.0 );

    # approximate displacement given one location and a destination

    my ( $x, $y ) = $geo->displacement( @origin, @dest );

    # approximate location given one location and displacement

    my @pos = $geo->location( $lat, $lon, $x, $y );

# ABSTRACT

Accurate latitude/longitude calculations.

# DESCRIPTION

Geo::Ellipsoid performs geometrical calculations on the surface of
an ellipsoid. An ellipsoid is a three-dimension object formed from
the rotation of an ellipse about one of its axes. The approximate
shape of the earth is an ellipsoid, so Geo::Ellipsoid can accurately
calculate distance and bearing between two widely-separated locations
on the earth's surface.

The shape of an ellipsoid is defined by the lengths of its
semi-major and semi-minor axes. The shape may also be specified by
the flattening ratio `f` as:

    f = ( semi-major - semi-minor ) / semi-major

which, since f is a small number, is normally given as the reciprocal
of the flattening `1/f`.

The shape of the earth has been surveyed and estimated differently
at different times over the years. The two most common sets of values
used to describe the size and shape of the earth in the United States
are 'NAD27', dating from 1927, and 'WGS84', from 1984. United States
Geological Survey topographical maps, for example, use one or the
other of these values, and commonly-available Global Positioning
System (GPS) units can be set to use one or the other.
See ["DEFINED ELLIPSOIDS"](#defined-ellipsoids) below for the ellipsoid survey values
that may be selected for use by Geo::Ellipsoid.

# CONSTRUCTOR

- new

    The new() constructor may be called with a hash list to set the value of the
    ellipsoid to be used, the value of the units to be used for angles and
    distances, and whether or not the output range of longitudes and bearing
    angles should be symmetric around zero or always greater than zero.
    The initial default constructor is equivalent to the following:

        my $geo = Geo::Ellipsoid->new(
          ellipsoid           => 'WGS84',
          angle_unit          => 'radians' ,
          distance_unit       => 'meter',
          longitude_symmetric => 0,
          bearing_symmetric   => 0,
        );

    The constructor arguments may be of any case and, with the exception of
    the ellipsoid value, abbreviated to their first three characters.
    Thus, ( UNI => 'DEG', DIS => 'FEE', Lon => 1, ell => 'NAD27', bEA => 0 )
    is valid.

# CLASS METHODS

- get\_ellipsoids

    Returns a list with the names all known ellipsoids.

# INSTANCE METHODS

## Setters

- set\_angle\_unit
- set\_units

    Set the angle unit used by the Geo::Ellipsoid object. The unit may
    also be set in the constructor of the object. The allowable values are
    'degrees' or 'radians'. The default is 'radians'. The unit value is
    not case sensitive and may be abbreviated to 3 letters. The unit of
    angle apply to both input and output latitude, longitude, and bearing
    values.

        $geo->set_angle_unit('degrees');

- set\_distance\_unit

    Set the distance unit used by the Geo::Ellipsoid object. The unit of distance
    may also be set in the constructor of the object. The recognized values are
    'meter', 'kilometer', 'mile', 'nm' (nautical mile), or 'foot'. The default is
    'meter'. The value is not case sensitive and may be abbreviated to 3 letters.

        $geo->set_distance_unit('kilometer');

    For any other unit of distance not recognized by this method, pass a numerical
    argument representing the length of the distance unit in meters. For example,
    to use units of furlongs, call

        $geo->set_distance_unit(201.168);

    The distance conversion factors used by this module are as follows:

        Unit          Units per meter
        --------      ---------------
        foot             0.3048
        kilometer     1000.0
        mile          1609.344
        nm            1852.0

- set\_ellipsoid

    Set the ellipsoid to be used by the Geo::Ellipsoid object. See
    ["DEFINED ELLIPSOIDS"](#defined-ellipsoids) below for the allowable values. The value
    may also be set by the constructor. The default value is 'WGS84'.

        $geo->set_ellipsoid('NAD27');

- set\_custom\_ellipsoid

    Sets the ellipsoid parameters to the specified semi-major axis (given in
    meters) and reciprocal flattening. A zero value for the reciprocal flattening
    will result in a sphere for the ellipsoid, and a warning message will be
    issued.

        $geo->set_custom_ellipsoid( 'sphere', 6378137, 0 );

- set\_longitude\_symmetric

    If called with no argument or a true argument, sets the range of output values
    for longitude to be symmetric around zero, i.e., in the range \[-pi,+pi)
    radians, \[-180,180) degrees etc. depending on the angle unit.

    If called with a false or undefined argument, sets the output angle range to be
    non-negative, i.e., \[0,2\*pi) radians, \[0, 360) degrees etc. depending on the
    angle unit.

        $geo->set_longitude_symmetric(1);

- set\_bearing\_symmetric

    If called with no argument or a true argument, sets the range of output values
    for bearing to be symmetric around zero, i.e., in the range \[-pi,+pi) radians,
    \[-180,180) degrees etc. depending on the angle unit.

    If called with a false or undefined argument, sets the output angle range to be
    non-negative, i.e., \[0,2\*pi) radians, \[0,360) degrees etc. depending on the
    angle unit.

        $geo->set_bearing_symmetric(1);

- set\_defaults

    Sets the defaults for the new() constructor method. Call with key, value pairs
    similar to new.

        Geo::Ellipsoid->set_defaults(
          ellipsoid           => 'GRS80',
          angle_unit          => 'degrees',
          distance_unit       => 'kilometer',
          longitude_symmetric => 1,
          bearing_symmetric   => 0
        );

    Keys and string values (except for the ellipsoid identifier) may be shortened
    to their first three letters and are case-insensitive:

        Geo::Ellipsoid->set_defaults(
          uni => 'deg',
          ell => 'GRS80',
          dis => 'kil',
          lon => 1,
          bea => 0
        );

## Getters

- get\_ellipsoid

    Returns the name of the ellipsoid.

- get\_equatorial\_radius

    Returns the equatorial radius in meters.

- get\_polar\_radius

    Returns the polar radius in meters.

- get\_geocentric\_radius ANGLE

    Returns the geocentric radius in meters, given a geocentric latitude. The
    geocentric latitude is the angle between the equatorial plane and the radius
    from centre to the point on the surface.

- get\_flattening

    Returns the flattening.

- get\_eccentricity

    Returns the eccentricity.

- get\_longitude\_symmetric

    Returns true if the longitude is symmetric around zero, and false otherwise.

- get\_bearing\_symmetric

    Returns true if the bearing is symmetric around zero, and false otherwise.

- get\_angle\_unit

    Returns the angle unit, i.e., the unit for latitude, longitude, and bearing.

- get\_distance\_unit

    Returns the distance unit.

## Calculations

- scales

    Returns a list consisting of the distance unit per angle of latitude
    and longitude (degrees or radians) at the specified latitude.
    These values may be used for fast approximations of distance
    calculations in the vicinity of some location.

        ( $lat_scale, $lon_scale ) = $geo->scales($lat0);
        $x = $lon_scale * ($lon - $lon0);
        $y = $lat_scale * ($lat - $lat0);

- range

    Returns the range in distance units between two specified locations given
    as latitude, longitude pairs.

        my $dist = $geo->range( $lat1, $lon1, $lat2, $lon2 );
        my $dist = $geo->range( @origin, @destination );

- bearing

    Returns the bearing in degrees or radians from the first location to
    the second. Zero bearing is true north.

        my $bearing = $geo->bearing( $lat1, $lon1, $lat2, $lon2 );

- at

    Returns the list (latitude,longitude) in degrees or radians that is a
    specified range and bearing from a given location.

        my( $lat2, $lon2 ) = $geo->at( $lat1, $lon1, $range, $bearing );

- to

    In list context, returns (range, bearing) between two specified locations.
    In scalar context, returns just the range.

        my( $dist, $theta ) = $geo->to( $lat1, $lon1, $lat2, $lon2 );
        my $dist = $geo->to( $lat1, $lon1, $lat2, $lon2 );

- displacement

    Returns the (x,y) displacement in distance units between the two specified
    locations.

        my( $x, $y ) = $geo->displacement( $lat1, $lon1, $lat2, $lon2 );

    NOTE: The x and y displacements are only approximations and only valid
    between two locations that are fairly near to each other. Beyond 10 kilometers
    or more, the concept of X and Y on a curved surface loses its meaning.

- location

    Returns the list (latitude,longitude) of a location at a given (x,y)
    displacement from a given location.

            my @loc = $geo->location( $lat, $lon, $x, $y );

# DEFINED ELLIPSOIDS

The following ellipsoids are defined in Geo::Ellipsoid, with the
semi-major axis in meters and the reciprocal flattening as shown.
The default ellipsoid is WGS84.

    Ellipsoid        Semi-Major Axis (m.)     1/Flattening
    ---------        -------------------     ---------------
    AIRY                 6377563.396         299.3249646
    AIRY-MODIFIED        6377340.189         299.3249646
    AUSTRALIAN           6378160.0           298.25
    BESSEL-1841          6377397.155         299.1528128
    CLARKE-1880          6378249.145         293.465
    EVEREST-1830         6377276.345         290.8017
    EVEREST-MODIFIED     6377304.063         290.8017
    FISHER-1960          6378166.0           298.3
    FISHER-1968          6378150.0           298.3
    GRS80                6378137.0           298.25722210088
    HOUGH-1956           6378270.0           297.0
    HAYFORD              6378388.0           297.0
    IAU76                6378140.0           298.257
    KRASSOVSKY-1938      6378245.0           298.3
    NAD27                6378206.4           294.9786982138
    NWL-9D               6378145.0           298.25
    SOUTHAMERICAN-1969   6378160.0           298.25
    SOVIET-1985          6378136.0           298.257
    WGS72                6378135.0           298.26
    WGS84                6378137.0           298.257223563

# LIMITATIONS

The methods should not be used on points which are too near the poles
(above or below 89 degrees), and should not be used on points which
are antipodal, i.e., exactly on opposite sides of the ellipsoid. The
methods will not return valid results in these cases.

# ACKNOWLEDGEMENTS

The conversion algorithms used here are Perl translations of Fortran
routines written by LCDR L. Pfeifer NGS Rockville MD that implement
T. Vincenty's Modified Rainsford's method with Helmert's elliptical
terms as published in "Direct and Inverse Solutions of Ellipsoid on
the Ellipsoid with Application of Nested Equations", T. Vincenty,
Survey Review, April 1975.

The Fortran source code files inverse.for and forward.for
may be obtained from

    ftp://ftp.ngs.noaa.gov/pub/pcsoft/for_inv.3d/source/

# AUTHOR

Peter John Acklam, `<pjacklam@gmail.com>` (current maintainer)

Jim Gibson, `<Jim@Gibson.org>` (original author)

# BUGS

See LIMITATIONS, above.

There are currently no known bugs.

Please report any bugs or feature requests via
[https://github.com/pjacklam/p5-Geo-Ellipsoid/issues](https://github.com/pjacklam/p5-Geo-Ellipsoid/issues).

Old bug reports and feature requests can be found at
[http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Ellipsoid](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Ellipsoid).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Ellipsoid

You can also look for information at:

- GitHub

    GitHub is a code hosting platform for version control and collaboration.

    [https://github.com/pjacklam/p5-Geo-Ellipsoid](https://github.com/pjacklam/p5-Geo-Ellipsoid)

- MetaCPAN

    A modern, open-source CPAN search engine, useful to view POD in HTML format.

    [https://metacpan.org/release/Geo-Ellipsoid](https://metacpan.org/release/Geo-Ellipsoid)

- CPANTS

    The CPANTS is a website that analyzes the Kwalitee (code metrics) of a
    distribution.

    [https://cpants.cpanauthors.org/dist/Geo-Ellipsoid](https://cpants.cpanauthors.org/dist/Geo-Ellipsoid)

- CPAN Testers Reports

    The CPAN Testers is a network of smoke testers who run automated tests on
    uploaded CPAN distributions.

    [http://www.cpantesters.org/distro/G/Geo-Ellipsoid.html](http://www.cpantesters.org/distro/G/Geo-Ellipsoid.html)

- CPAN Testers Matrix

    The CPAN Testers Matrix displays smoke test results for this distribution for
    various combinations of Perl version and operating systems.

    [http://matrix.cpantesters.org/?dist=Geo-Ellipsoid](http://matrix.cpantesters.org/?dist=Geo-Ellipsoid)

# COPYRIGHT & LICENSE

Copyright 2016-2021 Peter John Acklam, current maintainer.

Copyright 2005-2008 Jim Gibson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

# SEE ALSO

Geo::Distance, Geo::Ellipsoids

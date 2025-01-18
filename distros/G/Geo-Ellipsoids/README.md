# NAME

Geo::Ellipsoids - Package for standard Geo:: ellipsoid a, b, f and 1/f values.

# SYNOPSIS

    use Geo::Ellipsoids;
    my $obj = Geo::Ellipsoids->new();
    $obj->set('WGS84'); #default
    print "a=", $obj->a, "\n";
    print "b=", $obj->b, "\n";
    print "f=", $obj->f, "\n";
    print "i=", $obj->i, "\n";
    print "e=", $obj->e, "\n";
    print "n=", $obj->n(45), "\n";

# DESCRIPTION

Package for standard Geo:: ellipsoid a, b, f and 1/f values.

# CONSTRUCTOR

## new

The new() constructor may be called with any parameter that is appropriate to the set method.

    my $obj = Geo::Ellipsoid->new();

# METHODS

## initialize

## set

Method sets the current ellipsoid.  This method is called when the object is constructed (default is WGS84).

    $obj->set(); #default WGS84
    $obj->set('Clarke 1866'); #All built in ellipsoids are stored in meters
    $obj->set({a=>1, b=>1});  #Custom Sphere 1 unit radius

## list

Method returns a list of known ellipsoid names.

    my @list=$obj->list;

    my $list=$obj->list;
    while (@$list) {
      print "$_\n";
    }

## a

Method returns the value of the semi-major axis.

    my $a=$obj->a;

## b

Method returns the value of the semi-minor axis.

    my $b=$obj->b;  #b=a(1-f)

## f

Method returns the value of flatting

    my $f=$obj->f;  #f=(a-b)/a

## i

Method returns the value of the inverse flatting

    my $i = $obj->i; #i=1/f=a/(a-b)

## invf

Method synonym for the i method

    my $i = $obj->invf; #i=1/f

## e

Method returns the value of the first eccentricity, e.  This is the eccentricity of the earth's elliptical cross-section.

    my $e=$obj->e;

## e2

Method returns the value of eccentricity squared (e.g. e^2). This is not the second eccentricity, e' or e-prime see the "ep" method.

    my $e2 = sqrt($obj->e2); #e^2 = f(2-f) = 2f-f^2 = 1-b^2/a^2

## ep

Method returns the value of the second eccentricity, e' or e-prime.  The second eccentricity is related to the first eccentricity by the equation: 1=(1-e^2)(1+e'^2).

    my $ep = $obj->ep;

## ep2

Method returns the square of value of second eccentricity, e' (e-prime).  This is more useful in almost all equations.

    my $ep=sqrt($obj->ep2);  #ep2=(ea/b)^2=e2/(1-e2)=a^2/b^2-1

## n

Method returns the value of n given latitude (degrees).  Typically represented by the Greek letter nu, this is the radius of curvature of the ellipsoid perpendicular to the meridian plane.  It is also the distance from the point in question to the polar axis, measured perpendicular to the ellipsoid's surface.

    my $n = $obj->n($lat);

Note: Some define a variable n as (a-b)/(a+b) this is not that variable.

Note: It appears that n can also be calculated as 

    n = a^2/sqrt(a^2 * cos($lat)^2 + $b^2 * sin($lat)^2);

## n\_rad

Method returns the value of n given latitude (radians).

    my $n_rad = $obj->n_rad($lat);

Reference: John P. Snyder, "Map Projections: A Working Manual", USGS, page 25, equation (4-20) http://pubs.er.usgs.gov/usgspubs/pp/pp1395

## rho

rho is the radius of curvature of the earth in the meridian plane.

    my $rho=$obj->rho($lat);

## rho\_rad

rho is the radius of curvature of the earth in the meridian plane. Sometimes denoted as R'.

    my $rho = $obj->rho_rad($lat);

Reference: John P. Snyder, "Map Projections: A Working Manual", USGS, page 24, equation (4-18) http://pubs.er.usgs.gov/usgspubs/pp/pp1395

## polar\_circumference

Method returns the value of the semi-minor axis times 2\*PI.

    my $polar_circumference=$obj->polar_circumference;

## equatorial\_circumference

Method returns the value of the semi-major axis times 2\*PI.

    my $equatorial_circumference=$obj->equatorial_circumference;

## shortname

Method returns the shortname, which is the hash key, of the current ellipsoid

    my $shortname = $obj->shortname;

## longname

Method returns the long name of the current ellipsoid

    my $longname = $obj->longname;

## data

Method returns a hash reference for the ellipsoid definition data structure.

    my $datastructure = $obj->data;

## name2ref

Method returns a hash reference (e.g. {a=>6378137,i=>298.257223563}) when passed a valid ellipsoid name (e.g. 'WGS84').

    my $ref=$obj->name2ref('WGS84')

# AUTHOR

Michael R. Davis

# LICENSE

Copyright (c) 2006 Michael R. Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Geo::Forward](https://metacpan.org/pod/Geo::Forward), [Geo::Ellipsoid](https://metacpan.org/pod/Geo::Ellipsoid), [Geo::Coordinates::UTM](https://metacpan.org/pod/Geo::Coordinates::UTM), [Geo::GPS::Data::Ellipsoid](https://metacpan.org/pod/Geo::GPS::Data::Ellipsoid), [GIS::Distance](https://metacpan.org/pod/GIS::Distance)

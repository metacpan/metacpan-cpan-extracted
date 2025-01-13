# NAME

Geo::Spline - Calculate geographic locations between GPS fixes.

# SYNOPSIS

    use Geo::Spline;
    my $p0={time=>1160449100.67, #seconds
            lat=>39.197807,      #degrees
            lon=>-77.263510,     #degrees
            speed=>31.124,       #m/s
            heading=>144.8300};  #degrees clockwise from North
    my $p1={time=>1160449225.66,
            lat=>39.167718,
            lon=>-77.242278,
            speed=>30.615,
            heading=>150.5300};
    my $spline=Geo::Spline->new($p0, $p1);
    my %point=$spline->point(1160449150);
    print "Lat:", $point{"lat"}, ", Lon:", $point{"lon"}, "\n\n";

    my @points=$spline->pointlist();
    foreach (@points) {
      print "Lat:", $_->{"lat"}, ", Lon:", $_->{"lon"}, "\n";
    }

# DESCRIPTION

This program was developed to be able to calculate the position between two GPS fixes using a 2-dimensional 3rd order polynomial spline.

    f(t)  = A + B(t-t0)  + C(t-t0)^2 + D(t-t0)^3 #position in X and Y
    f'(t) = B + 2C(t-t0) + 3D(t-t0)^2            #velocity in X and Y

I did some simple Math (for an engineer with a math minor) to come up with these formulas to calculate the unknowns from our knowns.

    A = x0                                     # when (t-t0)=0 in f(t)
    B = v0                                     # when (t-t0)=0 in f'(t)
    C = (x1-A-B(t1-t0)-D(t1-t0)^3)/(t1-t0)^2   # solve for C from f(t)
    C = (v1-B-3D(t1-t0)^2)/2(t1-t0)            # solve for C from f'(t)
    D = (v1(t1-t0)+B(t1-t0)-2x1+2A)/(t1-t0)^3  # equate C=C then solve for D

# CONSTRUCTOR

## new

    my $spline=Geo::Spline->new($p0, $p1);

## initialize

# METHODS

## ellipsoid

Method to set or retrieve the current ellipsoid object.  The ellipsoid is a Geo::Ellipsoids object.

    my $ellipsoid=$obj->ellipsoid;  #Default is WGS84

    $obj->ellipsoid('Clarke 1866'); #Built in ellipsoids from Geo::Ellipsoids
    $obj->ellipsoid({a=>1});        #Custom Sphere 1 unit radius

## ABCD

## point

Method returns a single point from a single time.

    my $point=$spline->point($t1);
    my %point=$spline->point($t1);

## pointlist

Method returns a list of points from a list of times.

    my $list=$spline->pointlist($t1,$t2,$t3);
    my @list=$spline->pointlist($t1,$t2,$t3);

## timelist

Method returns a list of times (n+1).  The default will return a list with an integer number of seconds between spline end points.

    my $list=$spline->timelist($samples); 
    my @list=$spline->timelist(); 

# LIMITATIONS

I use a very rough conversion from degrees to meters and then back.  It is accurate for short distances.

# AUTHOR

Michael R. Davis

# LICENSE

Copyright (c) 2006-2025 Michael R. Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

http://search.cpan.org/src/MRDVT/Geo-Spline-0.16/doc/spline.xls
http://search.cpan.org/src/MRDVT/Geo-Spline-0.16/doc/spline.png

[Math::Spline](https://metacpan.org/pod/Math::Spline), [Geo::Ellipsoids](https://metacpan.org/pod/Geo::Ellipsoids)

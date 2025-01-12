# NAME

Geo::Constants - Package for standard Geo:: constants.

# SYNOPSIS

    use Geo::Constants qw{PI DEG RAD}; #import into namespace
    print "PI:  ", PI(), "\n";
    print "d/r: ", DEG(), "\n";
    print "r/d: ", RAD(), "\n";

    use Geo::Constants;                #Perl OO
    my $obj = Geo::Constants->new();
    print "PI:  ", $obj->PI, "\n";
    print "d/r: ", $obj->DEG, "\n";
    print "r/d: ", $obj->RAD, "\n";

# DESCRIPTION

# CONSTRUCTOR

## new

The new() constructor

    my $obj = Geo::Constants->new();

## initialize

# FUNCTIONS

## PI

    my $pi = $obj->PI;

    use Geo::Constants qw{PI};
    my $pi = PI();

## DEG

    my $degrees_per_radian = $obj->DEG;

    use Geo::Constants qw{DEG};
    my $degrees_per_radian = DEG();

UOM: degrees/radian

## RAD

    my $radians_per_degree = $obj->RAD;

    use Geo::Constants qw{DEG};
    my $radians_per_degree = RAD();

UOM: radians/degree

## KNOTS

1 nautical mile per hour = (1852/3600) m/s - United States Department of Commerce, National Institute of Standards and Technology, NIST Special Publication 330, 2001 Edition

Returns 1852/3600 m/s/knot

UOM: meters/second per knot

# AUTHOR

Michael R. Davis

# LICENSE

Copyright (c) 2006-2025 Michael R. Davis

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# SEE ALSO

[Geo::Functions](https://metacpan.org/pod/Geo::Functions), [Geo::Ellipsoids](https://metacpan.org/pod/Geo::Ellipsoids), [Astro::Constants](https://metacpan.org/pod/Astro::Constants)

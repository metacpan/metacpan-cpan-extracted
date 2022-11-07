# NAME

Geo::Functions - Package for standard Geo:: functions.

# SYNOPSIS

    use Geo::Functions qw{deg_rad deg_dms rad_deg}; #import into namespace
    print "Degrees: ", deg_rad(3.14/4), "\n";

    use Geo::Functions;
    my $obj = Geo::Functions->new;
    print "Degrees: ", $obj->deg_rad(3.14/2), "\n";

# DESCRIPTION

# CONVENTIONS

Function naming convention is "format of the return" underscore "format of the parameters."  For example, you can read the deg\_rad function as "degrees given radians" or "degrees from radians".

# CONSTRUCTOR

## new

The new() constructor

    my $obj = Geo::Functions->new();

# METHODS

## initialize

## deg\_dms

Degrees given degrees minutes seconds.

    my $deg = deg_dms(39, 29, 17.134);
    my $deg = deg_dms(39, 29, 17.134, 'N');

## deg\_rad

Degrees given radians.

    my $deg = deg_rad(3.14);

## rad\_deg

Radians given degrees.

    my $rad = rad_deg(90);

## rad\_dms

Radians given degrees minutes seconds.

    my $rad = rad_dms(45 30 20.0);

## round

Round to the nearest integer. This formula rounds toward +/- infinity.

    my $int = round(42.2);

## dms\_deg

Degrees minutes seconds given degrees.

    my ($d, $m, $s, $sign) = dms_deg($degrees, qw{N S});
    my ($d, $m, $s, $sign) = dms_deg($degrees, qw{E W});

## dm\_deg

Degrees minutes given degrees.

    my ($d, $m, $sign) = dm_deg($degrees, qw{N S});
    my ($d, $m, $sign) = dm_deg($degrees, qw{E W});

## mps\_knots

meters per second given knots

    my $mps = mps_knots(50.0);

## knots\_mps

knots given meters per second

    my $knots = knots_mps(25.0);

# BUGS

Please log on GitHub

# LIMITS

# AUTHOR

Michael R. Davis

# LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis

# SEE ALSO

[Geo::Constants](https://metacpan.org/pod/Geo::Constants), [Geo::Ellipsoids](https://metacpan.org/pod/Geo::Ellipsoids)

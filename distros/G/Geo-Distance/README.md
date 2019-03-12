# NAME

Geo::Distance - Calculate distances and closest locations. (DEPRECATED)

# SYNOPSIS

    use Geo::Distance;
    
    my $geo = new Geo::Distance;
    $geo->formula('hsin');
    
    $geo->reg_unit( 'toad_hop', 200120 );
    $geo->reg_unit( 'frog_hop' => 6 => 'toad_hop' );
    
    my $distance = $geo->distance( 'unit_type', $lon1,$lat1 => $lon2,$lat2 );
    
    my $locations = $geo->closest(
        dbh => $dbh,
        table => $table,
        lon => $lon,
        lat => $lat,
        unit => $unit_type,
        distance => $dist_in_unit
    );

# DESCRIPTION

This perl library aims to provide as many tools to make it as simple as possible to calculate
distances between geographic points, and anything that can be derived from that.  Currently
there is support for finding the closest locations within a specified distance, to find the
closest number of points to a specified point, and to do basic point-to-point distance
calculations.

# DEPRECATED

This module has been gutted and is now a wrapper around [GIS::Distance](https://metacpan.org/pod/GIS::Distance), please
use that module instead.

When switching from this module to [GIS::Distance](https://metacpan.org/pod/GIS::Distance) make sure you reverse the
coordinates when passing them to ["distance" in GIS::Distance](https://metacpan.org/pod/GIS::Distance#distance).  GIS::Distance takes
lat/lon pairs while Geo::Distance takes lon/lat pairs.

# STABILITY

The interface to Geo::Distance is fairly stable nowadays.  If this changes it 
will be noted here.

`0.21` - All distance calculations are now handled by [GIS::Distance](https://metacpan.org/pod/GIS::Distance).

`0.10` - The closest() method has a changed argument syntax and no longer supports array searches.

`0.09` - Changed the behavior of the reg\_unit function.

`0.07` - OO only, and other changes all over.

# FORMULAS

`alt` - See [GIS::Distance::ALT](https://metacpan.org/pod/GIS::Distance::ALT).

`cos` - See [GIS::Distance::Cosine](https://metacpan.org/pod/GIS::Distance::Cosine).

`gcd` - See [GIS::Distance::GreatCircle](https://metacpan.org/pod/GIS::Distance::GreatCircle).

`hsin` - See [GIS::Distance::Haversine](https://metacpan.org/pod/GIS::Distance::Haversine).

`mt` - See [GIS::Distance::MathTrig](https://metacpan.org/pod/GIS::Distance::MathTrig).

`null` - See [GIS::Distance::Null](https://metacpan.org/pod/GIS::Distance::Null).

`polar` - See [GIS::Distance::Polar](https://metacpan.org/pod/GIS::Distance::Polar).

`tv` - See [GIS::Distance::Vincenty](https://metacpan.org/pod/GIS::Distance::Vincenty).

# PROPERTIES

## UNITS

All functions accept a unit type to do the computations of distance with.  By default no units 
are defined in a Geo::Distance object.  You can add units with reg\_unit() or create some default 
units with default\_units().

## LATITUDE AND LONGITUDE

When a function needs a longitude and latitude, they must always be in decimal degree format.
Here is some sample code for converting from other formats to decimal:

    # DMS to Decimal
    my $decimal = $degrees + ($minutes/60) + ($seconds/3600);
    
    # Precision Six Integer to Decimal
    my $decimal = $integer * .000001;

If you want to convert from decimal radians to degrees you can use Math::Trig's rad2deg function.

# METHODS

## new

    my $geo = new Geo::Distance;
    my $geo = new Geo::Distance( no_units=>1 );

Returns a blessed Geo::Distance object.  The new constructor accepts one optional 
argument.

    no_units - Whether or not to load the default units. Defaults to 0 (false).
               kilometer, kilometre, meter, metre, centimeter, centimetre, millimeter, 
               millimetre, yard, foot, inch, light second, mile, nautical mile, 
               poppy seed, barleycorn, rod, pole, perch, chain, furlong, league, 
               fathom

## formula

    if($geo->formula eq 'hsin'){ ... }
    $geo->formula('cos');

Allows you to retrieve and set the formula that is currently being used to
calculate distances.  See the available ["FORMULAS"](#formulas).

`hsin` is the default.  Both `mt` and `cos` are inferior in speed
and accuracy to `hsin`.

## reg\_unit

    $geo->reg_unit( $radius, $key );
    $geo->reg_unit( $key1 => $key2 );
    $geo->reg_unit( $count1, $key1 => $key2 );
    $geo->reg_unit( $key1 => $count2, $key2 );
    $geo->reg_unit( $count1, $key1 => $count2, $key2 );

This method is used to create custom unit types.  There are several ways of calling it, 
depending on if you are defining the unit from scratch, or if you are basing it off 
of an existing unit (such as saying 12 inches = 1 foot ).  When defining a unit from 
scratch you pass the name and rho (radius of the earth in that unit) value.

So, if you wanted to do your calculations in human adult steps you would have to have an 
average human adult walk from the crust of the earth to the core (ignore the fact that 
this is impossible).  So, assuming we did this and we came up with 43,200 steps, you'd 
do something like the following.

    # Define adult step unit.
    $geo->reg_unit( 43200, 'adult step' );
    # This can be read as "It takes 43,200 adult_steps to walk the radius of the earth".

Now, if you also wanted to do distances in baby steps you might think "well, now I 
gotta get a baby to walk to the center of the earth".  But, you don't have to!  If you do some 
research you'll find (no research was actually conducted) that there are, on average, 
4.7 baby steps in each adult step.

    # Define baby step unit.
    $geo->reg_unit( 4.7, 'baby step' => 'adult step' );
    # This can be read as "4.7 baby steps is the same as one adult step".

And if we were doing this in reverse and already had the baby step unit but not 
the adult step, you would still use the exact same syntax as above.

## distance

    my $distance = $geo->distance( 'unit_type', $lon1,$lat1 => $lon2,$lat2 );

Calculates the distance between two lon/lat points.

## closest

    my $locations = $geo->closest(
        dbh => $dbh,
        table => $table,
        lon => $lon,
        lat => $lat,
        unit => $unit_type,
        distance => $dist_in_unit
    );

This method finds the closest locations within a certain distance and returns an 
array reference with a hash for each location matched.

The closest method requires the following arguments:

    dbh - a DBI database handle
    table - a table within dbh that contains the locations to search
    lon - the longitude of the center point
    lat - the latitude of the center point
    unit - the unit of measurement to use, such as "meter"
    distance - the distance, in units, from the center point to find locations

The following arguments are optional:

    lon_field - the name of the field in the table that contains the longitude, defaults to "lon"
    lat_field - the name of the field in the table that contains the latitude, defaults to "lat"
    fields - an array reference of extra field names that you would like returned with each location
    where - additional rules for the where clause of the sql
    bind - an array reference of bind variables to go with the placeholders in where
    sort - whether to sort the locations by their distance, making the closest location the first returned
    count - return at most these number of locations (implies sort => 1)

This method uses some very simplistic calculations to SQL select out of the dbh.  This 
means that the SQL should work fine on almost any database (only tested on MySQL and SQLite so far) and 
this also means that it is fast.  Once this sub set of locations has been retrieved 
then more precise calculations are made to narrow down the result set.  Remember, though, that 
the farther out your distance is, and the more locations in the table, the slower your searches will be.

# AUTHORS

    Aran Clary Deltac <bluefeet@cpan.org>
    gray <gray@cpan.org>
    Anirvan Chatterjee <anirvan@base.mx.org>
    Ævar Arnfjörð Bjarmason <avarab@gmail.com>
    Niko Tyni <ntyni@debian.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

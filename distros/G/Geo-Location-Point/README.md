# NAME

Geo::Location::Point - Location information

# VERSION

Version 0.13

# SYNOPSIS

Geo::Location::Point encapsulates geographical point data with latitude and longitude.
It supports distance calculations,
comparison between points,
and provides various convenience methods for attributes like latitude, longitude, and related string representations

    use Geo::Location::Point;

    my $location = Geo::Location::Point->new(latitude => 0.01, longitude => -71);

# SUBROUTINES/METHODS

## new

Initialise a new object, accepting latitude and longitude via a hash or hash reference.
Takes one optional argument 'key' which is an API key for [https://timezonedb.com](https://timezonedb.com) for looking up timezone data.

    $location = Geo::Location::Point->new({ latitude => 0.01, longitude => -71 });

## lat

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

## latitude

Synonym for lat().

## long

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

## lng

Synonym for long().

## longitude

Synonym for long().

## distance

Determine the distance between two geographical points,
returns a [Class::Measure::Length](https://metacpan.org/pod/Class%3A%3AMeasure%3A%3ALength) object.

## equal

Check if two points are identical within a small tolerance.

    my $loc1 = Geo::Location::Point->new(lat => 2, long => 2);
    my $loc2 = Geo::Location::Point->new(lat => 2, long => 2);
    print ($loc1 == $loc2), "\n";       # Prints 1

## not\_equal

Are two points different?

    my $loc1 = Geo::Location::Point->new(lat => 2, long => 2);
    my $loc2 = Geo::Location::Point->new(lat => 2, long => 2);
    print ($loc1 != $loc2), "\n";       # Prints 0

## tz

Returns the timezone of the location.
Needs [TimeZone::TimeZoneDB](https://metacpan.org/pod/TimeZone%3A%3ATimeZoneDB).

## timezone

Synonym for tz().

## as\_string

Generate a human-readable string describing the point,
incorporating additional attributes like city or country if available.

## as\_uri

Convert the point to a Geo URI scheme string (geo:latitude,longitude).
See [https://en.wikipedia.org/wiki/Geo\_URI\_scheme](https://en.wikipedia.org/wiki/Geo_URI_scheme).
Arguably it should return a [URI](https://metacpan.org/pod/URI) object instead.

## attr

Get or set arbitrary attributes, such as city or country.

    $location->city('London');
    $location->country('UK');
    print $location->as_string(), "\n";
    print "$location\n";        # Calls as_string

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# BUGS

There is no validation on the attribute in the AUTOLOAD method,
so typos such as "citty" will not be caught.

# SEE ALSO

[GIS::Distance](https://metacpan.org/pod/GIS%3A%3ADistance),
[Geo::Point](https://metacpan.org/pod/Geo%3A%3APoint),
[TimeZone::TimeZoneDB](https://metacpan.org/pod/TimeZone%3A%3ATimeZoneDB).

# LICENSE AND COPYRIGHT

Copyright 2019-2025 Nigel Horne.

The program code is released under the following licence: GPL2 for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at \`&lt;njh at nigelhorne.com>\`.

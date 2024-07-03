# NAME

Geo::Location::Point - Location information

# VERSION

Version 0.12

# SYNOPSIS

Geo::Location::Point stores a place/location by latitude and longitude

    use Geo::Location::Point;

    my $location = Geo::Location::Point->new(latitude => 0.01, longitude => -71);

# SUBROUTINES/METHODS

## new

    $location = Geo::Location::Point->new({ latitude => 0.01, longitude => -71 });

Takes one optional argument 'key' which is an API key for [https://timezonedb.com](https://timezonedb.com) for looking up timezone data.

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

Determine the distance between two locations,
returns a [Class::Measure::Length](https://metacpan.org/pod/Class%3A%3AMeasure%3A%3ALength) object.

## equal

Are two points the same?

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

Prints the object in human-readable format.

## as\_uri

Prints the object as a URI string.
See [https://en.wikipedia.org/wiki/Geo\_URI\_scheme](https://en.wikipedia.org/wiki/Geo_URI_scheme).
Arguably it should return a [URI](https://metacpan.org/pod/URI) object instead.

## attr

Get/set location attributes, e.g. city

    $location->city('London');
    $location->country('UK');
    print $location->as_string(), "\n";
    print "$location\n";        # Calls as_string

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# BUGS

# SEE ALSO

[GIS::Distance](https://metacpan.org/pod/GIS%3A%3ADistance),
[Geo::Point](https://metacpan.org/pod/Geo%3A%3APoint),
[TimeZone::TimeZoneDB](https://metacpan.org/pod/TimeZone%3A%3ATimeZoneDB).

# LICENSE AND COPYRIGHT

Copyright 2019-2024 Nigel Horne.

The program code is released under the following licence: GPL2 for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at \`&lt;njh at nigelhorne.com>\`.

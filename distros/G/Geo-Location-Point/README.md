# NAME

Geo::Location::Point -
Location information

# VERSION

Version 0.03

# SYNOPSIS

    use Geo::Location::Point;

    my $location = Geo::Location::Point->new();

# DESCRIPTION

Geo::Location::Point stores a place.

# METHODS

## new

    $location = Geo::Location::Point->new();

## lat

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

## long

    print 'Latitude: ', $location->lat(), "\n";
    print 'Longitude: ', $location->long(), "\n";

## distance

Determine the distance between two locations,
returns a [Class::Measure::Length](https://metacpan.org/pod/Class::Measure::Length) object.

## as\_string

Prints the object in human-readable format.

## attr

Get/set location attributes, e.g. city

    $location->city('London');
    $location->country('UK');
    print $location->as_string(), "\n";

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# BUGS

# SEE ALSO

[GIS::Distance](https://metacpan.org/pod/GIS::Distance),
[Geo::Point](https://metacpan.org/pod/Geo::Point)

# LICENSE AND COPYRIGHT

Copyright 2019 Nigel Horne.

The program code is released under the following licence: GPL2 for personal use on a single computer.
All other users (including Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at \`&lt;njh at nigelhorne.com>\`.

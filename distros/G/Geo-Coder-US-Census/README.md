[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/7736847150242974/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/7736847150242974/heads/master/)
[![Linux Build Status](https://travis-ci.org/nigelhorne/Geo-Coder-US-Census.svg?branch=master)](https://travis-ci.org/nigelhorne/Geo-Coder-US-Census)

# NAME

Geo::Coder::US::Census - Provides a Geo-Coding functionality for the US using [https://geocoding.geo.census.gov](https://geocoding.geo.census.gov)

# VERSION

Version 0.07

# SYNOPSIS

      use Geo::Coder::US::Census;

      my $geo_coder = Geo::Coder::US::Census->new();
      # Get geocoding results (as a hash decoded from JSON)
      my $location = $geo_coder->geocode(location => '4600 Silver Hill Rd., Suitland, MD');
      # Sometimes the server gives a 500 error on this
      $location = $geo_coder->geocode(location => '4600 Silver Hill Rd., Suitland, MD, USA');

# DESCRIPTION

Geo::Coder::US::Census provides geocoding functionality specifically for U.S. addresses by interfacing with the U.S. Census Bureau's geocoding service.
It allows developers to convert street addresses into geographical coordinates (latitude and longitude) by querying the Census Bureau's API.
Using [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) (or a user-supplied agent), the module constructs and sends an HTTP GET request to the API.

The module uses [Geo::StreetAddress::US](https://metacpan.org/pod/Geo%3A%3AStreetAddress%3A%3AUS) to break down a given address into its components (street, city, state, etc.),
ensuring that the necessary details for geocoding are present.

# METHODS

## new

    $geo_coder = Geo::Coder::US::Census->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::US::Census->new(ua => $ua);

## geocode

Geocode an address.
It accepts addresses provided in various forms -
whether as a single argument, a key/value pair, or within a hash reference -
making it easy to integrate into different codebases.
It decodes the JSON response from the API using [JSON::MaybeXS](https://metacpan.org/pod/JSON%3A%3AMaybeXS),
providing the result as a hash.
This allows easy extraction of latitude, longitude, and other details returned by the service.

    $location = $geo_coder->geocode(location => $location);
    # @location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'latt'}, "\n";
    print 'Longitude: ', $location->{'longt'}, "\n";

## ua

Accessor method to get and set UserAgent object used internally. You
can call _env\_proxy_ for example, to get the proxy information from
environment variables:

    $geo_coder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    $geo_coder->ua(LWP::UserAgent::Throttled->new());

## reverse\_geocode

    # $location = $geo_coder->reverse_geocode(latlng => '37.778907,-122.39732');

\# Similar to geocode except it expects a latitude/longitude parameter.

Not supported.
Croaks if this method is called.

## run

In addition to being used as a library within other Perl scripts,
[Geo::Coder::US::Census](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AUS%3A%3ACensus) can be run directly from the command line.
When invoked this way,
it accepts an address as input,
performs geocoding,
and prints the resulting data structure via [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper).

    perl Census.pm 1600 Pennsylvania Avenue NW, Washington DC

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

Based on [Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geocoding.geo.census.gov.

# BUGS

# SEE ALSO

[Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces), [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3)

https://www.census.gov/data/developers/data-sets/Geocoding-services.html

# LICENSE AND COPYRIGHT

Copyright 2017-2025 Nigel Horne.

This program is released under the following licence: GPL2

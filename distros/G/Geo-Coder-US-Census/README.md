[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/7736847150242974/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/7736847150242974/heads/master/)
[![Linux Build Status](https://travis-ci.org/nigelhorne/Geo-Coder-US-Census.svg?branch=master)](https://travis-ci.org/nigelhorne/Geo-Coder-US-Census)

# Geo::Coder::US::Census

Provides a Geo-Coding functionality for the US using [https://geocoding.geo.census.gov](https://geocoding.geo.census.gov)

# VERSION

Version 0.05

# SYNOPSIS

      use Geo::Coder::US::Census;

      my $geo_coder = Geo::Coder::US::Census->new();
      my $location = $geo_coder->geocode(location => '4600 Silver Hill Rd., Suitland, MD');
      # Sometimes the server gives a 500 error on this
      $location = $geo_coder->geocode(location => '4600 Silver Hill Rd., Suitland, MD, USA');

# DESCRIPTION

Geo::Coder::US::Census provides an interface to geocoding.geo.census.gov.  Geo::Coder::US no longer seems to work.

# METHODS

## new

    $geo_coder = Geo::Coder::US::Census->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::US::Census->new(ua => $ua);

## geocode

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

## run

You can also run this module from the command line:

    perl Census.pm 1600 Pennsylvania Avenue NW, Washington DC

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

Based on [Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo::Coder::GooglePlaces).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geocoding.geo.census.gov.

# BUGS

Should be called Geo::Coder::NA for North America.

# SEE ALSO

[Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo::Coder::GooglePlaces), [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML::GoogleMaps::V3)

https://www.census.gov/data/developers/data-sets/Geocoding-services.html

# LICENSE AND COPYRIGHT

Copyright 2017,2018 Nigel Horne.

This program is released under the following licence: GPL2

# NAME

Geo::Coder::US::Census - Provides a geocoding functionality using http:://geocoding.geo.census.gov for the US.

# VERSION

Version 0.02

# SYNOPSIS

      use Geo::Coder::US::Census;

      my $geocoder = Geo::Coder::US::Census->new();
      my $location = $geocoder->geocode(location => '4600 Silver Hill Rd., Suitland, MD, USA');

# DESCRIPTION

Geo::Coder::US::Census provides an interface to geocoding.geo.census.gov.  Geo::Coder::US no longer seems to work.

# METHODS

## new

    $geocoder = Geo::Coder::US::Census->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geocoder = Geo::Coder::US::Census->new(ua => $ua);

## geocode

    $location = $geocoder->geocode(location => $location);
    # @location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->{'latt'}, "\n";
    print 'Longitude: ', $location->{'longt'}, "\n";

## ua

Accessor method to get and set UserAgent object used internally. You
can call _env\_proxy_ for example, to get the proxy information from
environment variables:

    $geocoder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    $geocoder->ua(LWP::UserAgent::Throttled->new());

## reverse\_geocode

    # $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

\# Similar to geocode except it expects a latitude/longitude parameter.

Not supported.

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

Based on [Geo::Coder::Coder::Googleplaces](https://metacpan.org/pod/Geo::Coder::Coder::Googleplaces).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geocoding.geo.census.gov.

# BUGS

Should be called Geo::Coder::NA for North America.

# SEE ALSO

[Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo::Coder::GooglePlaces), [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML::GoogleMaps::V3)

https://www.census.gov/data/developers/data-sets/Geocoding-services.html

# LICENSE AND COPYRIGHT

Copyright 2017 Nigel Horne.

This program is released under the following licence: GPL2

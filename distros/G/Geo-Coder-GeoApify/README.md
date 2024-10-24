# NAME

Geo::Coder::GeoApify - Provides a Geo-Coding functionality using [https://www.geoapify.com/maps-api/](https://www.geoapify.com/maps-api/)

# VERSION

Version 0.09

# SYNOPSIS

      use Geo::Coder::GeoApify;

      my $geo_coder = Geo::Coder::GeoApify->new();
      my $location = $geo_coder->geocode(location => '10 Downing St., London, UK');

# DESCRIPTION

Geo::Coder::GeoApify provides an interface to https://www.geoapify.com/maps-api/,
a free Geo-Coding database covering many countries.

# METHODS

## new

    $geo_coder = Geo::Coder::GeoApify->new(apiKey => 'foo');

## geocode

    $location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'latt'}, "\n";
    print 'Longitude: ', $location->{'longt'}, "\n";

    @locations = $geo_coder->geocode('Portland, USA');
    print 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations), "\n";

## ua

Accessor method to get and set UserAgent object used internally. You
can call _env\_proxy_ for example, to get the proxy information from
environment variables:

    $geo_coder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;

    my $ua = LWP::UserAgent::Throttled->new({ 'api.geoapify.com' => 2 });
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::GeoApify->new({ ua => $ua, apiKey => 'foo' });

## reverse\_geocode

    $location = $geo_coder->reverse_geocode(lat => '37.778907, lon => -122.39732');

Similar to geocode except it expects a latitude/longitude parameter.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geoapify.com

# SEE ALSO

[Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces), [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3)

# LICENSE AND COPYRIGHT

Copyright 2024 Nigel Horne.

This program is released under the following licence: GPL2

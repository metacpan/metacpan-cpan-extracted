# NAME

Geo::Coder::GeoApify - Provides a Geo-Coding functionality using [https://www.geoapify.com/maps-api/](https://www.geoapify.com/maps-api/)

# VERSION

Version 0.02

# SYNOPSIS

    use Geo::Coder::GeoApify;

    my $geo_coder = Geo::Coder::GeoApify->new(apiKey => $ENV{'GEOAPIFY_KEY'});
    my $location = $geo_coder->geocode(location => '10 Downing St., London, UK');

# DESCRIPTION

Geo::Coder::GeoApify provides an interface to https://www.geoapify.com/maps-api/,
a free Geo-Coding database covering many countries.

- Caching

    Identical geocode requests are cached (using [CHI](https://metacpan.org/pod/CHI) or a user-supplied caching object),
    reducing the number of HTTP requests to the API and speeding up repeated queries.

    This module leverages [CHI](https://metacpan.org/pod/CHI) for caching geocoding responses.
    When a geocode request is made,
    a cache key is constructed from the request.
    If a cached response exists,
    it is returned immediately,
    avoiding unnecessary API calls.

- Rate-Limiting

    A minimum interval between successive API calls can be enforced to ensure that the API is not overwhelmed and to comply with any request throttling requirements.

    Rate-limiting is implemented using [Time::HiRes](https://metacpan.org/pod/Time%3A%3AHiRes).
    A minimum interval between API
    calls can be specified via the `min_interval` parameter in the constructor.
    Before making an API call,
    the module checks how much time has elapsed since the
    last request and,
    if necessary,
    sleeps for the remaining time.

# METHODS

## new

    $geo_coder = Geo::Coder::GeoApify->new(apiKey => $ENV{'GEOAPIFY_KEY'});

Creates a new `Geo::Coder::GeoApify` object with the provided apiKey.

It takes several optional parameters:

- `cache`

    A caching object.
    If not provided,
    an in-memory cache is created with a default expiration of one hour.

- `host`

    The API host endpoint.
    Defaults to [https://api.geoapify.com/v1/geocode](https://api.geoapify.com/v1/geocode).

- `min_interval`

    Minimum number of seconds to wait between API requests.
    Defaults to `0` (no delay).
    Use this option to enforce rate-limiting.

- `ua`

    An object to use for HTTP requests.
    If not provided, a default user agent is created.

## geocode

    $location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'features'}[0]{'geometry'}{'coordinates'}[1], "\n";
    print 'Longitude: ', $location->{'features'}[0]{'geometry'}{'coordinates'}[0], "\n";

    @locations = $geo_coder->geocode('Portland, USA');
    print 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations), "\n";

## ua

Accessor method to get and set UserAgent object used internally. You
can call _env\_proxy_ for example, to get the proxy information from
environment variables:

    $geo_coder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;

    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle({ 'api.geoapify.com' => 5 });
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::GeoApify->new({ ua => $ua, apiKey => $ENV{'GEOAPIFY_KEY'} });

## reverse\_geocode

    my $address = $geo_coder->reverse_geocode(lat => 37.778907, lon => -122.39732);
    print 'City: ', $address->{features}[0]->{'properties'}{'city'}, "\n";

Similar to geocode except it expects a latitude,longitude pair.

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

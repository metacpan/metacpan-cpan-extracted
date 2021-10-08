# NAME

Geo::Coder::Mapbox - Provides a Geo-Coding functionality using [https://mapbox.com](https://mapbox.com)

# VERSION

Version 0.01

# SYNOPSIS

      use Geo::Coder::Mapbox;

      my $geo_coder = Geo::Coder::Mapbox->new(access_token => $ENV{'MAPBOX'});
      my $location = $geo_coder->geocode(location => 'Washington, DC');

# DESCRIPTION

Geo::Coder::Mapbox provides an interface to mapbox.com, a free Geo-Coding database covering many countries.

# METHODS

## new

    $geo_coder = Geo::Coder::Mapbox->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::Mapbox->new(ua => $ua);

## geocode

    $location = $geo_coder->geocode(location => 'Toronto, Ontario, Canada');

    print 'Latitude: ', $location->{features}[0]->{center}[1], "\n";    # Latitude
    print 'Longitude: ', $location->{features}[0]->{center}[0], "\n";   # Longitude

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
    $ua->throttle({ 'mapbox.com' => 2 });
    $geo_coder->ua($ua);

## reverse\_geocode

    $location = $geo_coder->reverse_geocode(lnglat => '-122.39732,37.778907');

Similar to geocode except it expects a longitude/latitude (note the order) parameter.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

Based on [Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at mapbox.com.

# SEE ALSO

[Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces), [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3), [https://docs.mapbox.com/api/search/geocoding/](https://docs.mapbox.com/api/search/geocoding/)

# LICENSE AND COPYRIGHT

Copyright 2021 Nigel Horne.

This program is released under the following licence: GPL2

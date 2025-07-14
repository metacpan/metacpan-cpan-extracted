[![Linux Build Status](https://travis-ci.org/nigelhorne/Geo-Coder-XYZ.svg?branch=master)](https://travis-ci.org/nigelhorne/Geo-Coder-XYZ)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/81c3r325x8ytd7sn?svg=true)](https://ci.appveyor.com/project/nigelhorne/geo-coder-xyz)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/Geo-Coder-XYZ/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/Geo-Coder-XYZ?branch=master)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/Geo-Coder-XYZ/badge)](https://dependencyci.com/github/nigelhorne/Geo-Coder-XYZ)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/3980051779912539/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/3980051779912539/heads/master/)

# NAME

Geo::Coder::XYZ - Provides a Geo-Coding functionality using [https://geocode.xyz](https://geocode.xyz)

# VERSION

Version 0.10

# SYNOPSIS

      use Geo::Coder::XYZ;

      my $geo_coder = Geo::Coder::XYZ->new();
      my $location = $geo_coder->geocode(location => '10 Downing St., London, UK');

# DESCRIPTION

Geo::Coder::XYZ provides an interface to geocode.xyz, a free Geo-Coding database covering many countries.

# METHODS

## new

    $geo_coder = Geo::Coder::XYZ->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::XYZ->new(ua => $ua);

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
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle({ 'geocode.xyz' => 2 });
    $geo_coder->ua($ua);

## reverse\_geocode

    $location = $geo_coder->reverse_geocode(latlng => '37.778907,-122.39732');

Similar to geocode except it expects a latitude/longitude parameter.

# SUPPORT

This module is provided as-is without any warranty.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

Based on [Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geocode.xyz.

# SEE ALSO

[Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces), [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3)

# LICENSE AND COPYRIGHT

Copyright 2017-2025 Nigel Horne.

This program is released under the following licence: GPL2

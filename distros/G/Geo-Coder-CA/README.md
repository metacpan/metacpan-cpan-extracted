[![Linux Build Status](https://travis-ci.org/nigelhorne/Geo-Coder-CA.svg?branch=master)](https://travis-ci.org/nigelhorne/Geo-Coder-CA)
[![Windows Build Status](https://ci.appveyor.com/api/projects/status/xy5gf1mumgp3mg94?svg=true)](https://ci.appveyor.com/project/nigelhorne/geo-coder-ca)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/Geo-Coder-CA/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/Geo-Coder-CA?branch=master)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/Geo-Coder-CA/badge)](https://dependencyci.com/github/nigelhorne/Geo-Coder-CA)
[![CPAN](https://img.shields.io/cpan/v/Geo-Coder-CA.svg)](http://search.cpan.org/~nhorne/Geo-Coder-CA/)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/8113837670534727/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/8113837670534727/heads/master/)

# NAME

Geo::Coder::CA - Provides a Geo-Coding functionality using [https://geocoder.ca](https://geocoder.ca) for both Canada and the US.

# VERSION

Version 0.14

# SYNOPSIS

      use Geo::Coder::CA;

      my $geo_coder = Geo::Coder::CA->new();
      my $location = $geo_coder->geocode(location => '9235 Main St, Richibucto, New Brunswick, Canada');

# DESCRIPTION

Geo::Coder::CA provides an interface to geocoder.ca.
[Geo::Coder::Canada](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3ACanada) no longer seems to work.

# METHODS

## new

    $geo_coder = Geo::Coder::CA->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::CA->new(ua => $ua);

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

    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle('geocoder.ca' => 1);
    $geo_coder->ua($ua);

## reverse\_geocode

    $location = $geo_coder->reverse_geocode(latlng => '37.778907,-122.39732');

Similar to geocode except it expects a latitude/longitude parameter.

## run

You can also run this module from the command line:

    perl CA.pm 1600 Pennsylvania Avenue NW, Washington DC

# AUTHOR

Nigel Horne, `<njh@bandsman.co.uk>`

Based on [Geo::Coder::Googleplaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGoogleplaces).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geocoder.ca.

# BUGS

Should be called Geo::Coder::NA for North America.

# SEE ALSO

[Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces), [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3)

# LICENSE AND COPYRIGHT

Copyright 2017-2023 Nigel Horne.

This program is released under the following licence: GPL2

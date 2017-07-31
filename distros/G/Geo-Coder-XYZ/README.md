[![Linux Build Status](https://travis-ci.org/nigelhorne/Geo-Coder-XYZ.svg?branch=master)](https://travis-ci.org/nigelhorne/Geo-Coder-XYZ)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/81c3r325x8ytd7sn?svg=true)](https://ci.appveyor.com/project/nigelhorne/geo-coder-xyz)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/Geo-Coder-XYZ/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/Geo-Coder-XYZ?branch=master)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/Geo-Coder-XYZ/badge)](https://dependencyci.com/github/nigelhorne/Geo-Coder-XYZ)

# Geo::Coder::XYZ

Provides a geocoding functionality using https://geocode.xyz

# VERSION

Version 0.06

# SYNOPSIS

      use Geo::Coder::XYZ;

      my $geocoder = Geo::Coder::XYZ->new();
      my $location = $geocoder->geocode(location => '10 Downing St., London, UK');

# DESCRIPTION

Geo::Coder::XYZ provides an interface to geocode.xyz, a free geocode database covering many countries.

# METHODS

## new

    $geocoder = Geo::Coder::XYZ->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geocoder = Geo::Coder::XYZ->new(ua => $ua);

## geocode

    $location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->{'latt'}, "\n";
    print 'Longitude: ', $location->{'longt'}, "\n";

    @locations = $geocoder->geocode('Portland, USA');
    diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);
        

## ua

Accessor method to get and set UserAgent object used internally. You
can call _env\_proxy_ for example, to get the proxy information from
environment variables:

    $geocoder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;
    $geocoder->ua(LWP::UserAgent::Throttled->new());

## reverse\_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

Similar to geocode except it expects a latitude/longitude parameter.

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

Based on [Geo::Coder::Coder::Googleplaces](https://metacpan.org/pod/Geo::Coder::Coder::Googleplaces).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geocode.xyz.

# SEE ALSO

[Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo::Coder::GooglePlaces), [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML::GoogleMaps::V3)

# LICENSE AND COPYRIGHT

Copyright 2017 Nigel Horne.

This program is released under the following licence: GPL2

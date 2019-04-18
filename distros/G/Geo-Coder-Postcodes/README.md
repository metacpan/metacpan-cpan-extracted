[![Linux Build Status](https://travis-ci.org/nigelhorne/Geo-Coder-Postcodes.svg?branch=master)](https://travis-ci.org/nigelhorne/Geo-Coder-Postcodes)
[![Windows Build Status](https://ci.appveyor.com/api/projects/status/x9t8v45f27fuk7mm?svg=true)](https://ci.appveyor.com/project/nigelhorne/geo-coder-postcodes)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/Geo-Coder-Postcodes/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/Geo-Coder-Postcodes?branch=master)
[![CPAN](https://img.shields.io/cpan/v/Geo-Coder-Postcodes.svg)](http://search.cpan.org/~nhorne/Geo-Coder-Postcodes/)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/6314705722033970/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/6314705722033970/heads/master/)

# NAME

Geo::Coder::Postcodes - Provides a geocoding functionality using https://postcodes.io.

# VERSION

Version 0.06

# SYNOPSIS

      use Geo::Coder::Postcodes;

      my $geo_coder = Geo::Coder::Postcodes->new();
      my $location = $geo_coder->geocode(location => 'Margate');

# DESCRIPTION

Geo::Coder::Postcodes provides an interface to postcodes.io,
a free Geo-Coder database covering the towns in the UK.

# METHODS

## new

    $geo_coder = Geo::Coder::Postcodes->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::Postcodes->new(ua => $ua);

## geocode

    $location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'latitude'}, "\n";
    print 'Longitude: ', $location->{'logitude'}, "\n";

## ua

Accessor method to get and set UserAgent object used internally. You
can call _env\_proxy_ for example, to get the proxy information from
environment variables:

    $geo_coder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;
    $geo_coder->ua(LWP::UserAgent::Throttled->new());

## reverse\_geocode

    $location = $geo_coder->reverse_geocode(latlng => '37.778907,-122.39732');

Similar to geocode except it expects a latitude/longitude parameter.

# BUGS

Note that this most only works on towns and cities, some searches such as "Margate, Kent, UK"
may work, but you're best to search only for "Margate".

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

Based on [Geo::Coder::Coder::Googleplaces](https://metacpan.org/pod/Geo::Coder::Coder::Googleplaces).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at postcodes.io.

# SEE ALSO

[Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo::Coder::GooglePlaces), [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML::GoogleMaps::V3)

# LICENSE AND COPYRIGHT

Copyright 2017-2019 Nigel Horne.

This program is released under the following licence: GPL2

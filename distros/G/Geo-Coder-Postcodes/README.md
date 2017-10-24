[![CPAN](https://img.shields.io/cpan/v/Geo-Coder-Postcodes.svg)](http://search.cpan.org/~nhorne/Geo-Coder-Postcodes/)

# Geo::Coder::Postcodes

Provides a geocoding functionality using https://postcodes.io.

# VERSION

Version 0.04

# SYNOPSIS

      use Geo::Coder::Postcodes;

      my $geocoder = Geo::Coder::Postcodes->new();
      my $location = $geocoder->geocode(location => 'Margate');

# DESCRIPTION

Geo::Coder::Postcodes provides an interface to postcodes.io,
a free geocode database covering the towns in the UK.

# METHODS

## new

    $geocoder = Geo::Coder::Postcodes->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geocoder = Geo::Coder::Postcodes->new(ua => $ua);

## geocode

    $location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->{'latitude'}, "\n";
    print 'Longitude: ', $location->{'logitude'}, "\n";

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

Copyright 2017 Nigel Horne.

This program is released under the following licence: GPL2

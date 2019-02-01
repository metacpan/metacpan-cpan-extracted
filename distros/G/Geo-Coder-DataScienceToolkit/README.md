# NAME

Geo::Coder::DataScienceToolkit - Provides a geocoding functionality using
http://www.datasciencetoolkit.org/

# VERSION

Version 0.01

# SYNOPSIS

      use Geo::Coder::DataScienceToolkit;

      my $geocoder = Geo::Coder::DataScienceToolkit->new();
      my $location = $geocoder->geocode(location => '10 Downing St., London, UK');

# DESCRIPTION

Geo::Coder::DataScienceToolkit provides an interface to datasciencetoolkit,
a free geocode database covering the US and UK.

# METHODS

## new

    $geocoder = Geo::Coder::DataScienceToolkit->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geocoder = Geo::Coder::DataScienceToolkit->new(ua => $ua);

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

Based on [Geo::Coder::XYZ](https://metacpan.org/pod/Geo::Coder::XYZ).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at DSTK.

# SEE ALSO

[Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo::Coder::GooglePlaces),
[HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML::GoogleMaps::V3),
[http://www.datasciencetoolkit.org/about](http://www.datasciencetoolkit.org/about).

# LICENSE AND COPYRIGHT

Copyright 2019 Nigel Horne.

This program is released under the following licence: GPL2

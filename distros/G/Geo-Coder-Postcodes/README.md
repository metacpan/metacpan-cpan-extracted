## Name

Geo::Coder::Postcodes - Provides a geocoding functionality using [https://postcodes.io](https://postcodes.io).

## Version

Version 0.09

## Synopsis

```perl
  use Geo::Coder::Postcodes;

  my $geo_coder = Geo::Coder::Postcodes->new();
  my $location = $geo_coder->geocode(location => 'Margate');
```

## Description

Geo::Coder::Postcodes provides an interface to postcodes.io,
a free Geo-Coder database covering the towns in the UK.

## Methods

### New

```perl
$geo_coder = Geo::Coder::Postcodes->new();
my $ua = LWP::UserAgent->new();
$ua->env_proxy(1);
$geo_coder = Geo::Coder::Postcodes->new(ua => $ua);
```

### Geocode

```perl
$location = $geo_coder->geocode(location => $location);

print 'Latitude: ', $location->{'latitude'}, "\n";
print 'Longitude: ', $location->{'logitude'}, "\n";
```

### Ua

Accessor method to get and set UserAgent object used internally. You
can call _env\_proxy_ for example, to get the proxy information from
environment variables:

```
$geo_coder->ua()->env_proxy(1);
```

You can also set your own User-Agent object:

```perl
use LWP::UserAgent::Throttled;
$geo_coder->ua(LWP::UserAgent::Throttled->new());
```

### Reverse\_Geocode

```perl
$location = $geo_coder->reverse_geocode(latlng => '37.778907,-122.39732');
```

Similar to geocode except it expects a latitude/longitude parameter.

## Bugs

Note that this most only works on towns and cities, some searches such as "Margate, Kent, UK"
may work, but you're best to search only for "Margate".

## Author

Nigel Horne `<njh@nigelhorne.com>`

Based on [Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at postcodes.io.

## See Also

[Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces), [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3)

## License and Copyright

Copyright 2017-2026 Nigel Horne.

This program is released under the following licence: GPL2

## Name

Geo::Coder::DataScienceToolkit - Provides a geocoding functionality using
http://www.datasciencetoolkit.org/

## Version

Version 0.03

## Synopsis

```perl
  use Geo::Coder::DataScienceToolkit;

  my $geocoder = Geo::Coder::DataScienceToolkit->new();
  my $location = $geocoder->geocode(location => '10 Downing St., London, UK');
```

## Description

Geo::Coder::DataScienceToolkit provides an interface to datasciencetoolkit,
a free geocode database covering the US and UK.

## Methods

### New

```perl
$geocoder = Geo::Coder::DataScienceToolkit->new();
my $ua = LWP::UserAgent->new();
$ua->env_proxy(1);
$geocoder = Geo::Coder::DataScienceToolkit->new(ua => $ua);
```

### Geocode

```perl
$location = $geocoder->geocode(location => $location);

print 'Latitude: ', $location->{'results'}[0]->{'geometry'}->{'location'}->{'lat'}, 38.90, 1e-2); "\n";
print 'Longitude: ', delta_within($location->{'results'}[0]->{'geometry'}->{'location'}->{'lng'}, -77.04, 1e-2); "\n";

@locations = $geocoder->geocode('Portland, USA');
diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);
```

### Ua

Accessor method to get and set UserAgent object used internally. You
can call _env\_proxy_ for example, to get the proxy information from
environment variables:

```
$geocoder->ua()->env_proxy(1);
```

You can also set your own User-Agent object:

```perl
use LWP::UserAgent::Throttled;
$geocoder->ua(LWP::UserAgent::Throttled->new());
```

### Reverse\_Geocode

Reverse geocoding is not supported by datasciencetoolkit.org, so calls to
this will generate an error.

## Author

Nigel Horne <njh@bandsman.co.uk>

Based on [Geo::Coder::XYZ](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AXYZ).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at DSTK.

## See Also

[Geo::Coder::GooglePlaces](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGooglePlaces),
[HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3),
[http://www.datasciencetoolkit.org/about](http://www.datasciencetoolkit.org/about).

## Support

You can find documentation for this module with the perldoc command.

```
perldoc Geo::Coder::DataScienceToolKit
```

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Geo-Coder-DataScienceToolkit](https://metacpan.org/dist/Geo-Coder-DataScienceToolkit)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-DataScienceToolkit](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-DataScienceToolkit)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Geo-Coder-DataScienceToolkit](http://matrix.cpantesters.org/?dist=Geo-Coder-DataScienceToolkit)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Geo-Coder-DataScienceToolkit](http://deps.cpantesters.org/?module=Geo-Coder-DataScienceToolkit)

## License and Copyright

Copyright 2019-2026 Nigel Horne.

This program is released under the following licence: GPL2

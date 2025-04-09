# Geo::Coder::GeocodeFarm

[![CI](https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm/actions/workflows/ci.yaml/badge.svg)](https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm/actions/workflows/ci.yaml)
[![Trunk Check](https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm/actions/workflows/trunk.yaml/badge.svg)](https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm/actions/workflows/trunk.yaml)
[![CPAN](https://img.shields.io/cpan/v/Geo-Coder-GeocodeFarm)](https://metacpan.org/dist/Geo-Coder-GeocodeFarm)

## NAME

Geo::Coder::GeocodeFarm - Geocode addresses with the GeocodeFarm API

## SYNOPSIS

```perl

    use Geo::Coder::GeocodeFarm;

    my $geocoder = Geo::Coder::GeocodeFarm->new(
        key => 'YOUR-API-KEY-HERE',
    );

    my $result = $geocoder->geocode(
        location => '530 W Main St Anoka MN 55303 US',
    );
    printf "%f,%f\n",
        $result->{coordinates}{lat},
        $result->{coordinates}{lon};

    my $reverse = $geocoder->reverse_geocode(
        lat      => '45.2040305',
        lon      => '-93.3995728',
    );
    print $reverse->{formatted_address}, "\n";

```

## DESCRIPTION

The `Geo::Coder::GeocodeFarm` module provides an interface to the geocoding
functionality of the GeocodeFarm API v4.

## METHODS

## new

```perl

    $geocoder = Geo::Coder::GeocodeFarm->new(
        key    => 'YOUR-API-KEY-HERE',
        url    => 'https://api.geocode.farm/',
        ua     => HTTP::Tiny->new,
        parser => JSON->new->utf8,
        raise_failure => 1,
    );

```

Creates a new geocoding object with optional arguments.

An API key is required and can be obtained at
[https://geocode.farm/store/api-services/](https://geocode.farm/store/api-services/)

## geocode

```perl

    $result = $geocoder->geocode(
        location => $location,
    )

```

Forward geocoding takes a provided address or location and returns the
coordinate set for the requested location.

Method throws an error (or returns failure as nested list if raise\_failure
argument is false) if the service failed to find coordinates or wrong key was
used.

## reverse\_geocode

```perl

    $result = $geocoder->reverse_geocode(
        lat      => $latitude,
        lon      => $longitude,
    )

```

Reverse geocoding takes a provided coordinate set and returns the address for
the requested coordinates.

Method throws an error (or returns failure as nested list if raise\_failure
argument is false) if the service failed to find coordinates or wrong key was
used.

## SEE ALSO

[https://geocode.farm/](https://geocode.farm/)

## BUGS

If you find the bug or want to implement new features, please report it at
[https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm/issues](https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm/issues)

The code repository is available at
[https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm](https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm)

## AUTHOR

Piotr Roszatycki <dexter@cpan.org>

## LICENSE

Copyright (c) 2013, 2015, 2025 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)

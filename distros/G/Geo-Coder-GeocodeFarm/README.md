[![Build Status](https://travis-ci.org/dex4er/perl-Geo-Coder-GeocodeFarm.png?branch=master)](https://travis-ci.org/dex4er/perl-Geo-Coder-GeocodeFarm)

# NAME

Geo::Coder::GeocodeFarm - Geocode addresses with the GeocodeFarm API

# SYNOPSIS

    use Geo::Coder::GeocodeFarm;

    my $geocoder = Geo::Coder::GeocodeFarm->new(
        key => '3d517dd448a5ce1c2874637145fed69903bc252a',
    );
    my $result = $geocoder->geocode(
        location => '530 W Main St Anoka MN 55303 US',
        lang     => 'en',
        count    => 1,
    );
    printf "%f,%f",
        $result->{RESULTS}{COORDINATES}{latitude},
        $result->{RESULTS}{COORDINATES}{longitude};

# DESCRIPTION

The `Geo::Coder::GeocodeFarm` module provides an interface to the geocoding
functionality of the GeocodeFarm API v3.

# METHODS

## new

    $geocoder = Geo::Coder::GeocodeFarm->new(
        key    => '3d517dd448a5ce1c2874637145fed69903bc252a',
        url    => 'https://www.geocode.farm/v3/',
        ua     => HTTP::Tiny->new,
        parser => JSON->new->utf8,
        raise_failure => 1,
    );

Creates a new geocoding object with optional arguments.

An API key is optional and can be obtained at
[https://www.geocode.farm/dashboard/login/](https://www.geocode.farm/dashboard/login/)

`url` argument is optional and then the default address is http-based if
`key` argument is missing and https-based if `key` is provided.

`ua` argument is a [HTTP::Tiny](https://metacpan.org/pod/HTTP::Tiny) object by default and can be also set to
[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object.

New account can be registered at [https://www.geocode.farm/register/](https://www.geocode.farm/register/)

## geocode

    $result = $geocoder->geocode(
        location => $location,
        lang     => 'en',  # optional: 'en' or 'de'
        country  => 'US',  # optional
        count    => 1,     # optional
    )

Forward geocoding takes a provided address or location and returns the
coordinate set for the requested location as a nested list:

    {
        "geocoding_results": {
            "LEGAL_COPYRIGHT": {
                "copyright_notice": "Copyright (c) 2015 Geocode.Farm - All Rights Reserved.",
                "copyright_logo": "https:\/\/www.geocode.farm\/images\/logo.png",
                "terms_of_service": "https:\/\/www.geocode.farm\/policies\/terms-of-service\/",
                "privacy_policy": "https:\/\/www.geocode.farm\/policies\/privacy-policy\/"
            },
            "STATUS": {
                "access": "FREE_USER, ACCESS_GRANTED",
                "status": "SUCCESS",
                "address_provided": "530 W Main St Anoka MN 55303 US",
                "result_count": 1
            },
            "ACCOUNT": {
                "ip_address": "1.2.3.4",
                "distribution_license": "NONE, UNLICENSED",
                "usage_limit": "250",
                "used_today": "26",
                "used_total": "26",
                "first_used": "26 Mar 2015"
            },
            "RESULTS": [
                {
                    "result_number": 1,
                    "formatted_address": "530 West Main Street, Anoka, MN 55303, USA",
                    "accuracy": "EXACT_MATCH",
                    "ADDRESS": {
                        "street_number": "530",
                        "street_name": "West Main Street",
                        "locality": "Anoka",
                        "admin_2": "Anoka County",
                        "admin_1": "Minnesota",
                        "postal_code": "55303",
                        "country": "United States"
                    },
                    "LOCATION_DETAILS": {
                        "elevation": "UNAVAILABLE",
                        "timezone_long": "UNAVAILABLE",
                        "timezone_short": "America\/Menominee"
                    },
                    "COORDINATES": {
                        "latitude": "45.2041251174690",
                        "longitude": "-93.4003513528652"
                    },
                    "BOUNDARIES": {
                        "northeast_latitude": "45.2041251778513",
                        "northeast_longitude": "-93.4003513845523",
                        "southwest_latitude": "45.2027761197097",
                        "southwest_longitude": "-93.4017002802923"
                    }
                }
            ],
            "STATISTICS": {
                "https_ssl": "DISABLED, INSECURE"
            }
        }
    }

Method throws an error (or returns failure as nested list if raise\_failure
argument is false) if the service failed to find coordinates or wrong key was
used.

Methods throws an error if there was an other problem.

## reverse\_geocode

    $result = $geocoder->reverse_geocode(
        lat      => $latitude,
        lon      => $longtitude,
        lang     => 'en',  # optional: 'en' or 'de'
        country  => 'US',  # optional
        count    => 1,     # optional
    )

or

    $result = $geocoder->reverse_geocode(
        latlng => "$latitude,$longtitude",
        # ... optional args
    )

Reverse geocoding takes a provided coordinate set and returns the address for
the requested coordinates as a nested list. Its format is the same as for
["geocode"](#geocode) method.

Method throws an error (or returns failure as nested list if raise\_failure
argument is false) if the service failed to find coordinates or wrong key was
used.

Method throws an error if there was an other problem.

# SEE ALSO

[https://www.geocode.farm/](https://www.geocode.farm/)

# BUGS

If you find the bug or want to implement new features, please report it at
[https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm/issues](https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm/issues)

The code repository is available at
[http://github.com/dex4er/perl-Geo-Coder-GeocodeFarm](http://github.com/dex4er/perl-Geo-Coder-GeocodeFarm)

# AUTHOR

Piotr Roszatycki <dexter@cpan.org>

# LICENSE

Copyright (c) 2013, 2015 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)

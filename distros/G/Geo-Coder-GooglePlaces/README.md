[![Actions Status](https://github.com/nigelhorne/Geo-Coder-GooglePlaces/workflows/.github/workflows/all.yml/badge.svg)](https://github.com/nigelhorne/Geo-Coder-GooglePlaces/actions)
[![Travis Status](https://travis-ci.org/nigelhorne/geo-coder-googleplaces.svg?branch=master)](https://travis-ci.org/nigelhorne/geo-coder-googleplaces)
[![Appveyor status](https://ci.appveyor.com/api/projects/status/fe74iggarbf7vg17/branch/master?svg=true)](https://ci.appveyor.com/project/nigelhorne/geo-coder-googleplaces/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/geo-coder-googleplaces/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/geo-coder-googleplaces?branch=master)
[![CPAN](https://img.shields.io/cpan/v/Geo-Coder-GooglePlaces.svg)](http://search.cpan.org/~nhorne/Geo-Coder-GooglePlaces/)
[![Kritika Status](https://kritika.io/users/nigelhorne/repos/5894516992072296/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/5894516992072296/heads/master/)
[![Kwalitee](https://cpants.cpanauthors.org/dist/Geo-Coder-GooglePlaces.png)](http://cpants.cpanauthors.org/dist/Geo-Coder-GooglePlaces)

# NAME

Geo::Coder::GooglePlaces::V3 - Google Places Geocoding API V3

# VERSION

Version 0.06

# SYNOPSIS

    use Geo::Coder::GooglePlaces;

    my $geocoder = Geo::Coder::GooglePlaces->new();
    my $location = $geocoder->geocode(location => 'Hollywood and Highland, Los Angeles, CA');

# DESCRIPTION

Geo::Coder::GooglePlaces::V3 provides a geocoding functionality using Google Places API V3.

# SUBROUTINES/METHODS

## new

    $geocoder = Geo::Coder::GooglePlaces->new();
    $geocoder = Geo::Coder::GooglePlaces->new(language => 'ru');
    $geocoder = Geo::Coder::GooglePlaces->new(gl => 'ca');
    $geocoder = Geo::Coder::GooglePlaces->new(oe => 'latin1');

To specify the language of Google's response add `language` parameter
with a two-letter value. Note that adding that parameter does not
guarantee that every request returns translated data.

You can also set `gl` parameter to set country code (e.g. _ca_ for Canada).

You can ask for a character encoding other than utf-8 by setting the _oe_
parameter, but this is not recommended.

You can optionally use your Places Premier Client ID, by passing your client
code as the `client` parameter and your private key as the `key` parameter.
The URL signing for Premier Client IDs requires the _Digest::HMAC\_SHA1_
and _MIME::Base64_ modules. To test your client, set the environment
variables GMAP\_CLIENT and GMAP\_KEY before running v3\_live.t

    GMAP_CLIENT=your_id GMAP_KEY='your_key' make test

You can get a key from [https://console.developers.google.com/apis/credentials](https://console.developers.google.com/apis/credentials).

## geocode

    $location = $geocoder->geocode(location => $location);
    @location = $geocoder->geocode(location => $location);

Queries _$location_ to Google Places geocoding API and returns hash
reference returned back from API server.
When you call the method in
an array context, it returns all the candidates got back, while it
returns the 1st one in a scalar context.

When you'd like to pass non-ASCII string as a location, you should
pass it as either UTF-8 bytes or Unicode flagged string.

## reverse\_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');
    @location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

Similar to geocode except it expects a latitude/longitude parameter.

## ua

Accessor method to get and set UserAgent object used internally. You
can call _env\_proxy_ for example, to get the proxy information from
environment variables:

    $coder->ua->env_proxy(1);

You can also set your own User-Agent object:

    $coder->ua( LWP::UserAgent::Throttled->new() );

## key

Accessor method to get and set your Google API key.

    print $coder->key(), "\n";

# AUTHOR

Nigel Horne `<njh@bandsman.co.uk>`

Based on [Geo::Coder::Google](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AGoogle) by Tatsuhiko Miyagawa `<miyagawa@bulknews.net>`

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# BUGS

I believe that reverse may longer work.

# SEE ALSO

[Geo::Coder::Yahoo](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AYahoo)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::GooglePlaces

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Geo-Coder-GooglePlaces](https://metacpan.org/release/Geo-Coder-GooglePlaces)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-GooglePlaces](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-GooglePlaces)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Geo-Coder-GooglePlaces](http://matrix.cpantesters.org/?dist=Geo-Coder-GooglePlaces)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Geo::Coder::GooglePlaces](http://deps.cpantesters.org/?module=Geo::Coder::GooglePlaces)

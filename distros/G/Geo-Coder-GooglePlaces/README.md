# Geo::Coder::GooglePlaces::V3

Google Maps Geocoding API V3

# SYNOPSIS

    use Geo::Coder::GooglePlaces;

    my $geocoder = Geo::Coder::GooglePlaces->new();
    my $location = $geocoder->geocode( location => 'Hollywood and Highland, Los Angeles, CA' );

# DESCRIPTION

Geo::Coder::GooglePlaces::V3 provides a geocoding functionality using Google Maps API V3.

# METHODS

- new

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

    You can optionally use your Maps Premier Client ID, by passing your client
    code as the `client` parameter and your private key as the `key` parameter.
    The URL signing for Premier Client IDs requires the _Digest::HMAC\_SHA1_
    and _MIME::Base64_ modules. To test your client, set the environment
    variables GMAP\_CLIENT and GMAP\_KEY before running 02\_v3\_live.t

        GMAP_CLIENT=your_id GMAP_KEY='your_key' make test

- geocode

        $location = $geocoder->geocode(location => $location);
        @location = $geocoder->geocode(location => $location);

    Queries _$location_ to Google Maps geocoding API and returns hash
    reference returned back from API server. When you cann the method in
    an array context, it returns all the candidates got back, while it
    returns the 1st one in a scalar context.

    When you'd like to pass non-ascii string as a location, you should
    pass it as either UTF-8 bytes or Unicode flagged string.

- reverse\_geocode

        $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');
        @location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

    Similar to geocode except it expects a latitude/longitude parameter.

- ua

    Accessor method to get and set UserAgent object used internally. You
    can call _env\_proxy_ for example, to get the proxy information from
    environment variables:

        $coder->ua->env_proxy;

    You can also set your own User-Agent object:

        $coder->ua( LWPx::ParanoidAgent->new );

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

Based on [Geo::Coder::Google](https://metacpan.org/pod/Geo::Coder::Google) by Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Geo::Coder::Yahoo](https://metacpan.org/pod/Geo::Coder::Yahoo), [http://www.google.com/apis/maps/documentation/#Geocoding\_Examples](http://www.google.com/apis/maps/documentation/#Geocoding_Examples)

List of supported languages: [http://spreadsheets.google.com/pub?key=p9pdwsai2hDMsLkXsoM05KQ&gid=1](http://spreadsheets.google.com/pub?key=p9pdwsai2hDMsLkXsoM05KQ&gid=1)

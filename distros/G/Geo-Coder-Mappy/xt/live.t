use strict;
use warnings;
use Encode;
use Geo::Coder::Mappy;
use Test::More;

plan skip_all => 'MAPPY_TOKEN environment variable must be set'
    unless $ENV{MAPPY_TOKEN};

my $debug = $ENV{GEO_CODER_MAPPY_DEBUG};
diag "Set GEO_CODER_MAPPY_DEBUG to see request/response data"
    unless $debug;

my $has_ssl = LWP::UserAgent->is_protocol_supported('https');

my $geocoder = Geo::Coder::Mappy->new(
    token => $ENV{MAPPY_TOKEN},
    debug => $debug,
);
{
    my $address = '47 Rue de Charonne, 75011 Paris, France';
    my $location = $geocoder->geocode($address);
    is(
        $location->{AddressDetails}{Country}{CountryName},
        'France',
        'correct country name'
    );
    my ($lat, $lon) = split ',', $location->{Point}{coordinates};
    like($lat, qr/^2\.37/,  'approximate latitude');
    like($lon, qr/^48\.85/, 'approximate longitude');
}

{
    my $address = qq(Albrecht-Th\xE4r-Stra\xDFe 6, 48147 M\xFCnster, Germany);

    my $location = $geocoder->geocode($address);
    ok($location, 'latin1 bytes');
    is(
        $location->{AddressDetails}{Country}{CountryName},
        'Germany', 'latin1 bytes'
    );

    $location = $geocoder->geocode(decode('latin1', $address));
    ok($location, 'UTF-8 characters');
    is(
        $location->{AddressDetails}{Country}{CountryName},
        'Germany', 'UTF-8 characters'
    );

    $location = $geocoder->geocode(
        encode('utf-8', decode('latin1', $address))
    );
    ok($location, 'UTF-8 bytes');
    is(
        $location->{AddressDetails}{Country}{CountryName},
        'Germany', 'UTF-8 bytes'
    );
}
{
    my $city = decode('latin1', qq(Schm\xF6ckwitz));
    my $location = $geocoder->geocode("$city, Berlin, Germany");
    is(
        $location->{AddressDetails}{Country}{AdministrativeArea}{Locality}
                 ->{LocalityName},
        $city,
        'decoded character encoding of response'
    );
}

SKIP: {
    skip 'no SSL support', 1 unless $has_ssl;

    my $geocoder = Geo::Coder::Mappy->new(
        token => $ENV{MAPPY_TOKEN},
        https => 1,
        debug => $debug,
    );
    my $address = '47 Rue de Charonne, 75011 Paris, France';
    my $location = $geocoder->geocode($address);
    is(
        $location->{AddressDetails}{Country}{CountryName},
        'France',
        'https geocode'
    );
}

done_testing;

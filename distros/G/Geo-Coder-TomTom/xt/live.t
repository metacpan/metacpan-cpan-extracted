use strict;
use warnings;
use Encode;
use Geo::Coder::TomTom;
use Test::More;

unless ($ENV{TOMTOM_APIKEY}) {
    plan skip_all => 'TOMTOM_APIKEY environment variable must be set';
}

my $debug = $ENV{GEO_CODER_TOMTOM_DEBUG};
diag "Set GEO_CODER_TOMTOM_DEBUG to see request/response data"
    unless $debug;

my $geocoder = Geo::Coder::TomTom->new(
    apikey   => $ENV{TOMTOM_APIKEY},
    debug    => $debug,
    compress => 0,
);
{
    my $address = 'De Ruijterkade 154, Amsterdam, NL';
    my $location = $geocoder->geocode($address);
    is(
        $location->{city},
        'Amsterdam',
        "correct city for $address"
    );
}
{
    my $address = qq(Albrecht-Th\xE4r-Stra\xDFe 6, 48147 M\xFCnster, Germany);

    my $location = $geocoder->geocode($address);
    ok($location, 'latin1 bytes');
    is($location->{country}, 'Germany', 'latin1 bytes');

    $location = $geocoder->geocode(decode('latin1', $address));
    ok($location, 'UTF-8 characters');
    is($location->{country}, 'Germany', 'UTF-8 characters');

    TODO: {
        local $TODO = 'UTF-8 bytes';
        $location = $geocoder->geocode(
            encode('utf-8', decode('latin1', $address))
        );
        ok($location, 'UTF-8 bytes');
        is($location->{country}, 'Germany', 'UTF-8 bytes');
        is($location->{houseNumber}, 6, 'UTF-8 bytes: parsed street address');

        my $city = decode('latin1', qq(M\xFCnster));
        is(
            $location->{city}, $city,
            'decoded character encoding of response'
        );
    }
}

done_testing;

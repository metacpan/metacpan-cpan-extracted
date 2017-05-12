use strict;
use warnings;
use Encode;
use Geo::Coder::Navteq;
use LWP::UserAgent;
use Test::More;

plan skip_all => 'NAVTEQ_APPKEY environment variable must be set'
    unless $ENV{NAVTEQ_APPKEY};

my $debug = $ENV{GEO_CODER_NAVTEQ_DEBUG};
diag "Set GEO_CODER_NAVTEQ_DEBUG to see request/response data"
    unless $debug;

my $geocoder = Geo::Coder::Navteq->new(
    appkey => $ENV{NAVTEQ_APPKEY},
    debug  => $debug
);
{
    my $address = '425 West Randolph Street, Chicago, IL';
    my $location = $geocoder->geocode($address);
    is(
        $location->{PropertiesMajor}{Zip},
        60606,
        "correct zip code for $address"
    );
}
{
    my @locations = $geocoder->geocode('Main Street, Los Angeles, CA');
    ok(@locations > 1, 'there are many Main Streets in Los Angeles');
}
{
    my $address = qq(Albrecht-Th\xE4r-Stra\xDFe 6, 48147 M\xFCnster, Germany);

    my $location = $geocoder->geocode($address);
    ok($location, 'latin1 bytes');
    is($location->{PropertiesMajor}{Ctry}, 'DE', 'latin1 bytes');

    $location = $geocoder->geocode(decode('latin1', $address));
    ok($location, 'UTF-8 characters');
    is($location->{PropertiesMajor}{Ctry}, 'DE', 'UTF-8 characters');

    $location = $geocoder->geocode(
        encode('utf-8', decode('latin1', $address))
    );
    ok($location, 'UTF-8 bytes');
    is($location->{PropertiesMajor}{Ctry}, 'DE', 'UTF-8 bytes');
}

done_testing;

use strict;
use warnings;
use Encode qw(decode encode);
use Geo::Coder::Mapquest;
use LWP::UserAgent;
use Test::More;

plan skip_all => 'MAPQUEST_APIKEY environment variable must be set'
    unless $ENV{MAPQUEST_APIKEY};

my $debug = $ENV{GEO_CODER_MAPQUEST_DEBUG};
diag "Set GEO_CODER_MAPQUEST_DEBUG to see request/response data"
    unless $debug;

my $has_ssl = LWP::UserAgent->is_protocol_supported('https');

my $open = 0;
GOTO:

my $geocoder = Geo::Coder::Mapquest->new(
    apikey => $ENV{MAPQUEST_APIKEY},
    open   => $open,
    debug  => $debug,
);

{
    my $address = 'Hollywood & Highland, Los Angeles, CA';
    my $location = $geocoder->geocode($address);
    is($location->{postalCode}, 90028, "correct zip code for $address");
}
{
    my @locations = $geocoder->geocode('Main Street, Los Angeles, CA');
    ok(@locations > 1, 'there are many Main Streets in Los Angeles, CA');
}
{
    my $address = qq(Ch\xE2teau d Uss\xE9, 37420);

    my $location = $geocoder->geocode($address, country => 'FR');
    ok($location, 'latin1 bytes');
    TODO: {
        local $TODO = 'International locations';
        is($location->{adminArea1}, 'FR', 'latin1 bytes');
    }

    $location = $geocoder->geocode(
        location => decode('latin1', $address),
        country  => 'FR'
    );
    ok($location, 'UTF-8 characters');
    TODO: {
        local $TODO = 'International locations';
        is($location->{adminArea1}, 'FR', 'UTF-8 characters');
    }

    $location = $geocoder->geocode(
        location => encode('utf-8', decode('latin1', $address)),
        country  => 'FR',
    );
    ok($location, 'UTF-8 bytes');
    TODO: {
        local $TODO = 'International locations';
        is($location->{adminArea1}, 'FR', 'UTF-8 bytes');
    }
}

my @addresses = (
    'Los Liones Dr, Pacific Palisades, CA 90272',
    '2001 North Fuller Avenue, Los Angeles, CA',
    '4730 Crystal Springs Drive, Los Angeles, CA',
);

{
    my @locations = $geocoder->batch(\@addresses);
    is(@locations, 3, 'batch - number of results');
    for my $i (0..2) {
        is(
            $locations[$i]->[0]{providedLocation},
            $addresses[$i], 'batch - result ' . ($i+1)
        );
    }
}

SKIP: {
    skip 'no SSL support', 1 unless $has_ssl;

    my $geocoder = Geo::Coder::Mapquest->new(
        apikey => $ENV{MAPQUEST_APIKEY},
        https  => 1,
        debug  => $debug,
    );
    my $address = 'Hollywood & Highland, Los Angeles, CA';
    my $location = $geocoder->geocode($address);
    is($location->{postalCode}, 90028, 'https geocode');

    my @locations = $geocoder->batch(\@addresses);
    is(@locations, 3, 'https batch');
}

unless ($open) {
    diag 'Testing opendata server';
    $open = 1;
    goto 'GOTO';
}

done_testing;

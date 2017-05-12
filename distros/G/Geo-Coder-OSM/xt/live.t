use strict;
use warnings;
use Encode;
use Geo::Coder::OSM;
use LWP::UserAgent;
use Test::More;

my $debug = $ENV{GEO_CODER_OSM_DEBUG};
diag "Set GEO_CODER_OSM_DEBUG to see request/response data"
    unless $debug;

for my $source (qw(osm mapquest)) {
    my $geocoder = Geo::Coder::OSM->new(
        debug   => $debug,
        sources => $source,
    );
    {
        my $address = '132 Maney Hill Road, West Midlands, UK';
        my $forward = $geocoder->geocode($address);
        is(
            $forward->{address}{town},
            'Sutton Coldfield',
            "correct town for $address"
        );
        my $road = $forward->{address}{road};

        my ($lat, $lon) = @$forward{qw(lat lon)};
        my $reverse = $geocoder->reverse_geocode(lat => $lat, lon => $lon);
        is(
            $reverse->{address}{road},
            $forward->{address}{road},
            'correct street for lat/lon',
        );
    }
    {
        my $address = qq(Champs-\xC9lys\xE9es, 75008);

        my $location = $geocoder->geocode($address);
        ok($location, 'latin1 bytes');
        is($location->{address}{country}, 'France', 'latin1 bytes');

        $location = $geocoder->geocode(decode('latin1', $address));
        ok($location, 'UTF-8 characters');
        is($location->{address}{country}, 'France', 'UTF-8 characters');

        TODO: {
            local $TODO = 'UTF-8 bytes';
            $location = $geocoder->geocode(
                encode('utf-8', decode('latin1', $address))
            );
            ok($location, 'UTF-8 bytes');
            is($location->{address}{country}, 'France', 'UTF-8 bytes');
        }
    }
    {
        my $city = decode('latin1', qq(Schm\xF6ckwitz));
        my $location = $geocoder->geocode("$city, Berlin, Germany");
        is(
            $location->{address}{suburb}, $city,
            'decoded character encoding of response'
        );
    }
}

done_testing;

use strict;
use warnings;
use Encode qw(decode encode);
use Geo::Coder::Multimap;
use Test::More;

unless ($ENV{MULTIMAP_APIKEY}) {
    plan skip_all => 'MULTIMAP_APIKEY environment variable must be set';
}
else {
    plan tests => 8;
}

my $geocoder = Geo::Coder::Multimap->new(apikey => $ENV{MULTIMAP_APIKEY});
{
    my $address = 'Hollywood & Highland, Los Angeles, CA, US';
    my $location = $geocoder->geocode($address);
    is(
        $location->{address}{postal_code},
        90028,
        "correct zip code for $address"
    );
}
{
    my @locations = $geocoder->geocode('Main Street, Los Angeles, CA');
    ok(@locations > 1, 'there are many Main Streets in Los Angeles, CA');
}
{
    my $address = qq(Ch\xE2teau d Uss\xE9, 37420, FR);

    my $location = $geocoder->geocode($address);
    ok($location, 'latin1 bytes');
    is($location->{address}{country_code}, 'FR', 'latin1 bytes');

    $location = $geocoder->geocode(decode('latin1', $address));
    ok($location, 'UTF-8 characters');
    is($location->{address}{country_code}, 'FR', 'UTF-8 characters');

    $location = $geocoder->geocode(
        encode('utf-8', decode('latin1', $address))
    );
    ok($location, 'UTF-8 bytes');
    is($location->{address}{country_code}, 'FR', 'UTF-8 bytes');
}

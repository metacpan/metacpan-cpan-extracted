use strict;
use utf8;
use Test::Number::Delta within => 1e-4;
use Test::More;
use Encode ();
use Geo::Coder::GooglePlaces;

if ($ENV{TEST_GEOCODER_GOOGLE_LIVE} || $ENV{'GMAP_KEY'}) {
  plan tests => 14;
} else {
  plan skip_all => 'Not running live tests. Set $ENV{TEST_GEOCODER_GOOGLE_LIVE} = 1 to enable';
}

{
    my $geocoder = Geo::Coder::GooglePlaces->new(apiver => 3, key => $ENV{GMAP_KEY});
    my $location = $geocoder->geocode('548 4th Street, San Francisco, CA');
    delta_ok($location->{geometry}{location}{lat}, 37.778907);
    delta_ok($location->{geometry}{location}{lng}, -122.39760);
}

SKIP: {
    skip "google.co.jp suspended geocoding JP characters", 1;
    my $geocoder = Geo::Coder::GooglePlaces->new(apikey => $ENV{GMAP_KEY}, host => 'maps.google.co.jp');
    my $location = $geocoder->geocode("東京都港区赤坂2-14-5");
    delta_ok($location->{Point}->{coordinates}->[0], 139.737808);
}

# as per http://code.google.com/apis/maps/documentation/geocoding/#CountryCodes
{
    my $geocoder_es = Geo::Coder::GooglePlaces->new(apiver => 3, gl => 'es', key => $ENV{GMAP_KEY});
    my $location_es = $geocoder_es->geocode('Toledo');
    delta_ok($location_es->{geometry}{location}{lng}, -4.0273231);
    my $geocoder_us = Geo::Coder::GooglePlaces->new(apiver => 3, key => $ENV{GMAP_KEY});
    my $location_us = $geocoder_us->geocode('Toledo');
    delta_ok($location_us->{geometry}{location}{lng}, -83.53787);
}

# URL signing
{
    # sample clientID from http://code.google.com/apis/maps/documentation/webservices/index.html#URLSigning
    my $client = $ENV{GMAP_CLIENT};
    my $key    = $ENV{GMAP_KEY};
    my $geocoder = Geo::Coder::GooglePlaces->new( apiver => 3, client => $client, key => $key );
    my $location = $geocoder->geocode(location => 'New York');
    delta_ok($location->{geometry}{location}{lat}, 40.71278, 'Latitude for NYC');
    delta_ok($location->{geometry}{location}{lng}, -74.0059731, 'Longitude for NYC');
}

{
    my $geocoder = Geo::Coder::GooglePlaces->new(apiver => 3, key => $ENV{GMAP_KEY});
    my $location = $geocoder->geocode('fdhkjafhdkjfhadskjfhasjklfhdlsak');
    is( $location, undef, "No location on zero results" );
}

SKIP: {
    my $geocoder_utf8 = Geo::Coder::GooglePlaces->new(apiver => 3, oe => 'utf8', key => $ENV{GMAP_KEY});
    my $location_utf8 = $geocoder_utf8->geocode('Bělohorská 80, 6, Czech Republic');
    # is($location_utf8->{formatted_address}, 'Bělohorská 1685/80, Břevnov, 169 00 Praha-Praha 6, Czech Republic');
    is($location_utf8->{formatted_address}, 'Bělohorská 1685/80, 169 00 Praha 6-Břevnov, Czechia');
}

# Reverse Geocoding
{
    my $geocoder = Geo::Coder::GooglePlaces->new(apiver => 3, key => $ENV{GMAP_KEY});

    my $location = $geocoder->reverse_geocode(latlng => '31.5494486689568,-97.1467727422714');
    like( $location->{formatted_address}, qr/Waco, TX/, 'reverse geocode' );

    $location = $geocoder->reverse_geocode('42.3222599,-83.1763145');
    like( $location->{formatted_address}, qr/Dearborn, MI/, 'reverse geocode' );
}

# Test components - country
{
    my $geocoder = Geo::Coder::GooglePlaces->new(apiver => 3, components => { country => 'ES'});

    my $location = $geocoder->geocode(location => 'santa cruz');
    like( $location->{formatted_address}, qr/Santa Cruz de Tenerife/, 'santa cruz de tenerife' );
    like( $location->{formatted_address}, qr/Spain/, 'santa cruz - make sure is in spain' );
}

# Test components - country + administrative_area
{
    my $geocoder = Geo::Coder::GooglePlaces->new(apiver => 3, components => { country => 'US', administrative_area => 'TX'});

    my $location = $geocoder->geocode(location => 'Torun');
    like( $location->{formatted_address}, qr/Texas, USA/, 'Texas, USA' );
}

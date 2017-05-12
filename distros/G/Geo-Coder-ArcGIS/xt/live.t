use strict;
use warnings;
use Encode;
use Geo::Coder::ArcGIS;
use Test::More;

my $debug = $ENV{GEO_CODER_ARCGIS_DEBUG};
note "Set GEO_CODER_ARCGIS_DEBUG to see request/response data"
    unless $debug;

my $with_ssl = 0;

GOTO:

my $geocoder = Geo::Coder::ArcGIS->new(
    debug => $debug,
    https => $with_ssl,
);
{
    my $address = '380 New York Street, Redlands, CA';
    my $location = $geocoder->geocode($address);
    like(
        $location->{location}{y},
        qr/^34\.057/,
        "approximate latitude code for $address",
    );
    like(
        $location->{location}{x},
        qr/^-117\.194/,
        "approximate longitude code for $address"
    );
}

{
    my $address = qq(Albrecht-Th\xE4r-Stra\xDFe 6, 48147 M\xFCnster, Germany);

    my $location = $geocoder->geocode($address);
    ok($location, 'latin1 bytes');
    like($location->{location}{y}, qr/^51\.982/, 'latin1 bytes',);
    like($location->{location}{x}, qr/^7\.636/,  'latin1 bytes');

    $location = $geocoder->geocode(decode('latin1', $address));
    ok($location, 'UTF-8 characters');
    like($location->{location}{y}, qr/^51\.982/, 'UTF-8 characters',);
    like($location->{location}{x}, qr/^7\.636/,  'UTF-8 characters');


    $location = $geocoder->geocode(
        encode('utf-8', decode('latin1', $address))
    );
    ok($location, 'UTF-8 bytes');
    like($location->{location}{y}, qr/^51\.982/, 'UTF-8 bytes',);
    like($location->{location}{x}, qr/^7\.636/,  'UTF-8 bytes');
}

TODO: {
    local $TODO = 'Multiple addresses';
    my @locations = $geocoder->geocode('Main Street, Los Angeles, CA');
    ok(@locations > 1, 'there are many Main Streets in Los Angeles, CA');
}

SKIP: {
    skip 'no SSL support', 1
        unless LWP::UserAgent->is_protocol_supported('https');
    last if $with_ssl;
    note '';
    note 'Testing with SSL';;
    note '*'x75;
    $with_ssl = 1;
    goto 'GOTO';
}

done_testing;

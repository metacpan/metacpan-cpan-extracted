use strict;
use warnings;
use Encode;
use Geo::Coder::Bing;
use LWP::UserAgent;
use Test::More;

unless ($ENV{BING_MAPS_KEY}) {
    plan skip_all => 'BING_MAPS_KEY environment variable must be set';
}

my $debug = $ENV{GEO_CODER_BING_DEBUG};
unless ($debug) {
    diag "Set GEO_CODER_BING_DEBUG to see request/response data";
}

my $has_ssl = LWP::UserAgent->is_protocol_supported('https');

diag "";
diag "Testing the REST API geocoder";
print "*" x 75, "\n";

my $geocoder = Geo::Coder::Bing->new(
    key   => $ENV{BING_MAPS_KEY},
    debug => $debug
);
{
    my $address  = 'One Microsoft Way, Redmond, WA';
    my $location = $geocoder->geocode($address);
    like(
        $location->{address}{postalCode},
        qr/^98052\b/,
        "correct zip code for $address"
    );

    $location = $geocoder->geocode($address, incl => 'ciso2,queryParse');
    is($location->{address}{countryRegionIso2}, 'US', 'countryRegionIso2 param');
    ok($location->{queryParseValues}, 'queryParseValues param');
}
{
    my @locations = $geocoder->geocode('Main Street');
    ok(@locations > 1, 'there are many Main Streets');
}
{
    my $address = qq(Albrecht-Th\xE4r-Stra\xDFe 6, 48147 M\xFCnster, Germany);

    my $location = $geocoder->geocode($address);
    ok($location, 'latin1 bytes');
    is($location->{address}{countryRegion}, 'Germany', 'latin1 bytes');

    $location = $geocoder->geocode(decode('latin1', $address));
    ok($location, 'UTF-8 characters');
    is($location->{address}{countryRegion}, 'Germany', 'UTF-8 characters');

    $location = $geocoder->geocode(
        encode('utf-8', decode('latin1', $address))
    );
    ok($location, 'UTF-8 bytes');
    is($location->{address}{countryRegion}, 'Germany', 'UTF-8 bytes');
}
{
    my $address = decode('latin1', qq(Schm\xF6ckwitz, Berlin, Germany));
    my $expected = decode('latin1', qq(Schm\xF6ckwitz, BE, Germany));

    my $location = $geocoder->geocode($address);
    is(
        $location->{address}{formattedAddress}, $expected,
        'decoded character encoding of response'
    );
}

{
    my ($lat, $lon) = qw(47.640068 -122.129858);
    my $location = $geocoder->reverse_geocode(lat => $lat, lon => $lon);
    like(
        $location->{address}{formattedAddress},
        qr/\bMicrosoft Way, Redmond, WA\b/,
        "correct reverse geocode for $lat,$lon",
    );
}


SKIP: {
    skip 'no SSL support', 1 unless $has_ssl;

    $geocoder = Geo::Coder::Bing->new(
        key   => $ENV{BING_MAPS_KEY},
        https => 1,
        debug => $debug
    );
    my $address  = 'One Microsoft Way, Redmond, WA';
    my $location = $geocoder->geocode($address);
    like($location->{address}{postalCode}, qr/^98052\b/, 'https');
}

diag "";
diag "Testing the AJAX API geocoder";
print "*" x 75, "\n";

$geocoder = do {
    # Silence the missing key warning.
    local $SIG{__WARN__} = sub { };

    Geo::Coder::Bing->new(debug => $debug);
};
{
    my $address  = 'One Microsoft Way, Redmond, WA';
    my $location = $geocoder->geocode($address);
    like(
        $location->{Address}{PostalCode},
        qr/^98052\b/,
        "correct zip code for $address"
    );
}
{
    my @locations = $geocoder->geocode('Main Street');
    ok(@locations > 1, 'there are many Main Streets');
}
{
    my $address = qq(Albrecht-Th\xE4r-Stra\xDFe 6, 48147 M\xFCnster, Germany);

    my $location = $geocoder->geocode($address);
    ok($location, 'latin1 bytes');
    is($location->{Address}{CountryRegion}, 'Germany', 'latin1 bytes');

    $location = $geocoder->geocode(decode('latin1', $address));
    ok($location, 'UTF-8 characters');
    is($location->{Address}{CountryRegion}, 'Germany', 'UTF-8 characters');

    $location = $geocoder->geocode(
        encode('utf-8', decode('latin1', $address))
    );
    ok($location, 'UTF-8 bytes');
    is($location->{Address}{CountryRegion}, 'Germany', 'UTF-8 bytes');
}
{
    my $address = decode('latin1', qq(Schm\xF6ckwitz, Berlin, Germany));
    my $expected = decode('latin1', qq(Schm\xF6ckwitz, BE, Germany));

    my $location = $geocoder->geocode($address);
    is(
        $location->{Address}{FormattedAddress}, $expected,
        'decoded character encoding of response'
    );
}

SKIP: {
    skip 'no SSL support', 1 unless $has_ssl;

    $geocoder = do {
        # Silence the missing key warning.
        local $SIG{'__WARN__'} = sub { };

        Geo::Coder::Bing->new(
            https => 1,
            debug => $debug
        );
    };
    my $address = 'One Microsoft Way, Redmond, WA';
    my $location = $geocoder->geocode($address);
    like($location->{Address}{PostalCode}, qr/^98052\b/, 'https');
}

done_testing;

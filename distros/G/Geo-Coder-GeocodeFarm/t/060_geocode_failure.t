#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

use Test::Deep;
use Test::Exception;

use Geo::Coder::GeocodeFarm;

my $ua = My::Mock::HTTP::Tiny->new;

{
    my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua];

    can_ok $geocode, qw(geocode);

    throws_ok {
        $geocode->geocode(no => 'location');
    } qr/Attribute .* is required/;
}

{
    my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua];

    can_ok $geocode, qw(geocode);

    throws_ok {
        $geocode->geocode(location => '530 W Main St Anoka MN 55303 US');
    } qr/FAILED, ACCESS_DENIED/;

    is $ua->{url}, 'https://www.geocode.farm/v3/json/forward/?addr=530+W+Main+St+Anoka+MN+55303+US&key=xxx', 'url matches';
}

{
    my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua, raise_failure => 0];

    can_ok $geocode, qw(geocode);

    my $result = $geocode->geocode(location => '530 W Main St Anoka MN 55303 US');

    isa_ok $result, 'HASH';

    cmp_deeply $result, {
        'LEGAL_COPYRIGHT' => {
            'copyright_logo' => 'https://www.geocode.farm/images/logo.png',
            'privacy_policy' => 'https://www.geocode.farm/policies/privacy-policy/',
            'copyright_notice' => 'Copyright (c) 2015 Geocode.Farm - All Rights Reserved.',
            'terms_of_service' => 'https://www.geocode.farm/policies/terms-of-service/'
        },
        'STATISTICS' => {
            'https_ssl' => 'ENABLED, SECURE'
        },
        'STATUS' => {
            'access' => 'API_KEY_INVALID',
            'status' => 'FAILED, ACCESS_DENIED'
        },
    }, '$result matches deeply';

    is $ua->{url}, 'https://www.geocode.farm/v3/json/forward/?addr=530+W+Main+St+Anoka+MN+55303+US&key=xxx', 'url matches';
}


package My::Mock;

sub new {
    my ($class) = @_;
    return bless +{} => $class;
}


package My::Mock::HTTP::Tiny;

use base 'My::Mock';

sub get {
    my ($self, $url) = @_;
    $self->{url} = $url;
    my $content = << 'END';
{
    "geocoding_results": {
        "LEGAL_COPYRIGHT": {
            "copyright_notice": "Copyright (c) 2015 Geocode.Farm - All Rights Reserved.",
            "copyright_logo": "https:\/\/www.geocode.farm\/images\/logo.png",
            "terms_of_service": "https:\/\/www.geocode.farm\/policies\/terms-of-service\/",
            "privacy_policy": "https:\/\/www.geocode.farm\/policies\/privacy-policy\/"
        },
        "STATUS": {
            "access": "API_KEY_INVALID",
            "status": "FAILED, ACCESS_DENIED"
        },
        "STATISTICS": {
            "https_ssl": "ENABLED, SECURE"
        }
    }
}
END
    my $res = {
        protocol => 'HTTP/1.1',
        status => 200,
        reason => 'OK',
        success => 1,
        content => $content,
    };
    return $res;
}

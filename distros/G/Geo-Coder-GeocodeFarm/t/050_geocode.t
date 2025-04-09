#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use Test::Deep;

use Geo::Coder::GeocodeFarm;

my $ua = My::Mock::HTTP::Tiny->new();
my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua];

can_ok $geocode, qw(geocode);

my $expected = {
    accuracy => "EXACT_MATCH",
    address  => {
        admin_1      => "MN",
        admin_2      => "Anoka County",
        country      => "United States",
        full_address => "530 W Main St, Anoka, MN 55303",
        house_number => 530,
        locality     => "Anoka",
        postal_code  => 55303,
        street_name  => "W Main St",
    },
    coordinates => { lat => 45.2039740622073, lon => -93.4003153027115 },
};

{
    my $result = $geocode->geocode(location => '530 W Main St Anoka MN 55303 US');

    isa_ok $result, 'HASH';

    cmp_deeply $result, $expected, '$result matches deeply';

    is $ua->{url}, 'https://api.geocode.farm/forward/?addr=530+W+Main+St+Anoka+MN+55303+US&key=xxx',
        'url matches';
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
    my $content = <<'END';
{
    "LEGAL": {
        "notice": "This system is the property of Geocode.Farm and any information contained herein is Copyright (c) Geocode.Farm. Usage is subject to the Terms of Service.",
        "terms": "https:\/\/geocode.farm\/policies\/terms-of-service\/",
        "privacy": "https:\/\/geocode.farm\/policies\/privacy-policy\/"
    },
    "STATUS": {
        "key": "VALID",
        "status": "SUCCESS",
        "request": "VALID",
        "credit_used": "1"
    },
    "USER": {
        "key": "FAKE-API-KEY",
        "name": "Fake Name",
        "email": "fake.email@example.com",
        "usage_limit": "250",
        "used_today": "1",
        "remaining_limit": 249
    },
    "RESULTS": {
        "request": {
            "addr": "530 W Main St Anoka MN 55303 US"
        },
        "result": {
            "coordinates": {
                "lat": "45.2039740622073",
                "lon": "-93.4003153027115"
            },
            "address": {
                "full_address": "530 W Main St, Anoka, MN 55303",
                "house_number": "530",
                "street_name": "W Main St",
                "locality": "Anoka",
                "admin_2": "Anoka County",
                "admin_1": "MN",
                "country": "United States",
                "postal_code": "55303"
            },
            "accuracy": "EXACT_MATCH"
        }
    }
}
END
    my $res = {
        protocol => 'HTTP/1.1',
        status   => 200,
        reason   => 'OK',
        success  => 1,
        content  => $content,
    };
    return $res;
}

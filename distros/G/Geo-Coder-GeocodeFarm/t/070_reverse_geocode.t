#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use Test::Deep;

use Geo::Coder::GeocodeFarm;

my $ua = My::Mock::LWP::UserAgent->new;
my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua];

can_ok $geocode, qw(reverse_geocode);

my $expected = {
    'accuracy'          => 'EXACT_MATCH',
    'formatted_address' => '500 W Main St, Anoka, MN 55303, United States',
    'locality'          => 'Anoka',
    'latitude'          => '45.2035740615438',
    'street_name'       => 'W Main St',
    'longitude'         => '-93.3995153025847',
    'house_number'      => '500',
    'admin_2'           => 'Anoka Co.',
    'admin_1'           => 'MN',
    'postal_code'       => '55303',
    'country'           => 'United States'
};

{
    my $result = $geocode->reverse_geocode(lat => '45.2040305', lon => '-93.3995728');

    isa_ok $result, 'HASH';

    cmp_deeply $result, $expected, '$result matches deeply';

    is $ua->{url}, 'https://api.geocode.farm/reverse/?lat=45.2040305&lon=-93.3995728&key=xxx', 'url matches';
}

package My::Mock;

sub new {
    my ($class) = @_;
    return bless +{} => $class;
}

package LWP::UserAgent;

sub _placeholder { }

package HTTP::Response;

sub _placeholder { }

package My::Mock::LWP::UserAgent;

use base 'My::Mock', 'LWP::UserAgent';

sub get {
    my ($self, $url) = @_;
    $self->{url} = $url;
    return My::Mock::HTTP::Response->new;
}

package My::Mock::HTTP::Response;

use base 'My::Mock', 'HTTP::Response';

sub is_success {
    return 1;
}

sub decoded_content {
    return <<'END';
{
    "LEGAL": {
        "notice": "This system is the property of Geocode.Farm and any information contained herein is Copyright (c) Geocode.Farm. Usage is subject to the Terms of Service.",
        "terms": "https:\/\/geocode.farm\/policies\/terms-of-service\/",
        "privacy": "https:\/\/geocode.farm\/policies\/privacy-policy\/"
    },
    "STATUS": {
        "key": "VALID",
        "request": "VALID",
        "status": "SUCCESS",
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
            "point": "-93.3995728 45.2040305",
            "latitude": "45.2040305",
            "longitude": "-93.3995728"
        },
        "result": {
            "0": {
                "house_number": "500",
                "street_name": "W Main St",
                "locality": "Anoka",
                "admin_2": "Anoka Co.",
                "admin_1": "MN",
                "country": "United States",
                "postal_code": "55303",
                "formatted_address": "500 W Main St, Anoka, MN 55303, United States",
                "latitude": "45.2035740615438",
                "longitude": "-93.3995153025847"
            },
            "accuracy": "EXACT_MATCH"
        }
    }
}
END
}

#!/usr/bin/perl

use strict;
use warnings;

use utf8;

use Test::More tests => 5;

use Test::Deep;
use Test::Exception;

use Geo::Coder::GeocodeFarm;

my $ua = My::Mock::HTTP::Tiny->new;

{
    my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua];

    can_ok $geocode, qw(geocode);

    my $result = $geocode->geocode(location => 'Łask, Poland');

    isa_ok $result, 'HASH';

    is $result->{address}{full_address}, 'Łask, Poland', '$result full_address';

    is $ua->{url}, 'https://api.geocode.farm/forward/?addr=%C5%81ask%2C+Poland&key=xxx',
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
            "addr": "Łask, Poland"
        },
        "result": {
            "coordinates": {
                "lat": "51.5929948452996",
                "lon": "19.1334783134829"
            },
            "address": {
                "full_address": "Łask, Poland",
                "locality": "Łask",
                "admin_2": "Łask County",
                "admin_1": "ŁD",
                "country": "Poland"
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

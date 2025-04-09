#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use Test::Deep;
use Test::Exception;

use Geo::Coder::GeocodeFarm;

my $ua = My::Mock::HTTP::Tiny->new;

{
    my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua];

    can_ok $geocode, qw(geocode);

    throws_ok {
        $geocode->geocode(no => 'location');
    }
    qr/Attribute .* is required/;
}

{
    my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua];

    can_ok $geocode, qw(geocode);

    throws_ok {
        $geocode->geocode(location => 'non-existing address');
    }
    qr/404 Not found/;

    is $ua->{url}, 'https://api.geocode.farm/forward/?addr=non-existing+address&key=xxx',
        'url matches';
}

{
    my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua, raise_failure => 0];

    can_ok $geocode, qw(geocode);

    is $geocode->geocode(location => 'non-existing address'), undef,
        'result is undef';

    is $ua->{url}, 'https://api.geocode.farm/forward/?addr=non-existing+address&key=xxx',
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
    my $res = {
        protocol => 'HTTP/1.1',
        status   => 404,
        reason   => 'Not found',
        success  => '',
        content  => <<'END',
{
    "LEGAL": {
        "notice": "This system is the property of Geocode.Farm and any information contained herein is Copyright (c) Geocode.Farm. Usage is subject to the Terms of Service.",
        "terms": "https:\/\/geocode.farm\/policies\/terms-of-service\/",
        "privacy": "https:\/\/geocode.farm\/policies\/privacy-policy\/"
    },
    "STATUS": {
        "key": "VALID",
        "status": "NO_RESULTS",
        "request": "VALID",
        "credit_used": "0"
    },
    "USER": {
        "key": "FAKE-API-KEY",
        "name": "Fake Name",
        "email": "fake.email@example.com",
        "usage_limit": "250",
        "used_today": "1",
        "remaining_limit": 249
    }
}
END
    };
    return $res;
}

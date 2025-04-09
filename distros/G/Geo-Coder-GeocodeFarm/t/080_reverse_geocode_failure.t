#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use Test::Deep;
use Test::Exception;

use Geo::Coder::GeocodeFarm;

my $ua = My::Mock::LWP::UserAgent->new;

{
    my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua];

    can_ok $geocode, qw(geocode);

    throws_ok {
        $geocode->reverse_geocode(no => 'latlon');
    }
    qr/Attribute .* is required/;
}

{
    my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua];

    can_ok $geocode, qw(geocode);

    throws_ok {
        $geocode->reverse_geocode(lat => '0.00', lon => '0.00');
    }
    qr/404 Not found/;

    is $ua->{url}, 'https://api.geocode.farm/reverse/?lat=0.00&lon=0.00&key=xxx',
        'url matches';
}

{
    my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua, raise_failure => 0];

    can_ok $geocode, qw(geocode);

    is $geocode->reverse_geocode(lat => '0.00', lon => '0.00'), undef,
        'result is undef';

    is $ua->{url}, 'https://api.geocode.farm/reverse/?lat=0.00&lon=0.00&key=xxx',
        'url matches';
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
    return 0;
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
        "status": "NO_RESULTS",
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
}

sub status_line {
    return '404 Not found';
}

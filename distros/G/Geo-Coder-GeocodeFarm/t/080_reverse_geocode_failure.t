#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

use Test::Deep;
use Test::Exception;

use Geo::Coder::GeocodeFarm;

my $ua = My::Mock::LWP::UserAgent->new;

{
    my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua, url => 'http://www.geocode.farm/v3/'];

    can_ok $geocode, qw(geocode);

    throws_ok {
        $geocode->geocode(no => 'latlng');
    } qr/Attribute .* is required/;
}

{
    my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua, url => 'http://www.geocode.farm/v3/'];

    can_ok $geocode, qw(reverse_geocode);

    throws_ok {
        $geocode->reverse_geocode(latlng => '45.2040305,-93.3995728');
    } qr/FAILED, ACCESS_DENIED/;

    is $ua->{url}, 'http://www.geocode.farm/v3/json/reverse/?lat=45.2040305&lon=-93.3995728&key=xxx', 'url matches';
}

{
    my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [key => 'xxx', ua => $ua, url => 'http://www.geocode.farm/v3/', raise_failure => 0];

    can_ok $geocode, qw(reverse_geocode);

    my $result = $geocode->reverse_geocode(latlng => '45.2040305,-93.3995728');

    isa_ok $result, 'HASH';

    cmp_deeply $result, {
        'LEGAL_COPYRIGHT' => {
            'copyright_logo' => 'https://www.geocode.farm/images/logo.png',
            'privacy_policy' => 'https://www.geocode.farm/policies/privacy-policy/',
            'copyright_notice' => 'Copyright (c) 2015 Geocode.Farm - All Rights Reserved.',
            'terms_of_service' => 'https://www.geocode.farm/policies/terms-of-service/'
        },
        'STATISTICS' => {
            'https_ssl' => 'DISABLED, INSECURE'
        },
        'STATUS' => {
            'access' => 'API_KEY_INVALID',
            'status' => 'FAILED, ACCESS_DENIED'
        },
    }, '$result matches deeply';

    is $ua->{url}, 'http://www.geocode.farm/v3/json/reverse/?lat=45.2040305&lon=-93.3995728&key=xxx', 'url matches';
}


package My::Mock;

sub new {
    my ($class) = @_;
    return bless +{} => $class;
}


package LWP::UserAgent;

sub get { }


package HTTP::Response;

sub is_success { }

sub decoded_content { }


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
    return << 'END';
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
            "https_ssl": "DISABLED, INSECURE"
        }
    }
}
END
}

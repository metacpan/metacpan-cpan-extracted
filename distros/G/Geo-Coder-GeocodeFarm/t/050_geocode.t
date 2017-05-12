#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use Test::Deep;

use Geo::Coder::GeocodeFarm;

my $ua = My::Mock::HTTP::Tiny->new;
my $geocode = new_ok 'Geo::Coder::GeocodeFarm' => [ua => $ua];

can_ok $geocode, qw(geocode);

my $expected = {
    'ACCOUNT' => {
        'ip_address' => '1.2.3.4',
        'used_today' => '28',
        'distribution_license' => 'NONE, UNLICENSED',
        'first_used' => '26 Mar 2015',
        'used_total' => '28',
        'usage_limit' => '250'
    },
    'LEGAL_COPYRIGHT' => {
        'copyright_logo' => 'https://www.geocode.farm/images/logo.png',
        'privacy_policy' => 'https://www.geocode.farm/policies/privacy-policy/',
        'copyright_notice' => 'Copyright (c) 2015 Geocode.Farm - All Rights Reserved.',
        'terms_of_service' => 'https://www.geocode.farm/policies/terms-of-service/'
    },
    'RESULTS' => [
        {
            'formatted_address' => '530 West Main Street, Anoka, MN 55303, USA',
            'ADDRESS' => {
                'street_name' => 'West Main Street',
                'postal_code' => '55303',
                'street_number' => '530',
                'locality' => 'Anoka',
                'admin_1' => 'Minnesota',
                'country' => 'United States',
                'admin_2' => 'Anoka County'
            },
            'LOCATION_DETAILS' => {
                'timezone_long' => 'UNAVAILABLE',
                'elevation' => 'UNAVAILABLE',
                'timezone_short' => 'America/Menominee'
            },
            'result_number' => 1,
            'accuracy' => 'EXACT_MATCH',
            'BOUNDARIES' => {
                'southwest_longitude' => '-93.4017002802923',
                'northeast_longitude' => '-93.4003513351005',
                'southwest_latitude' => '45.2027761197094',
                'northeast_latitude' => '45.2041251364687'
            },
            'COORDINATES' => {
                'longitude' => '-93.4003513716516',
                'latitude' => '45.2041251738751'
            }
        }
    ],
    'STATISTICS' => {
        'https_ssl' => 'DISABLED, INSECURE'
    },
    'STATUS' => {
        'address_provided' => '530 W Main St Anoka MN 55303 US',
        'access' => 'FREE_USER, ACCESS_GRANTED',
        'status' => 'SUCCESS',
        'result_count' => 1
    },
};

{
    my $result = $geocode->geocode(location => '530 W Main St Anoka MN 55303 US');

    isa_ok $result, 'HASH';

    cmp_deeply $result, $expected, '$result matches deeply';

    is $ua->{url}, 'http://www.geocode.farm/v3/json/forward/?addr=530+W+Main+St+Anoka+MN+55303+US', 'url matches';
}

{
    my $result = $geocode->geocode(addr => '530 W Main St Anoka MN 55303 US');

    isa_ok $result, 'HASH';

    cmp_deeply $result, $expected, '$result matches deeply';

    is $ua->{url}, 'http://www.geocode.farm/v3/json/forward/?addr=530+W+Main+St+Anoka+MN+55303+US', 'url matches';
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
            "access": "FREE_USER, ACCESS_GRANTED",
            "status": "SUCCESS",
            "address_provided": "530 W Main St Anoka MN 55303 US",
            "result_count": 1
        },
        "ACCOUNT": {
            "ip_address": "1.2.3.4",
            "distribution_license": "NONE, UNLICENSED",
            "usage_limit": "250",
            "used_today": "28",
            "used_total": "28",
            "first_used": "26 Mar 2015"
        },
        "RESULTS": [
            {
                "result_number": 1,
                "formatted_address": "530 West Main Street, Anoka, MN 55303, USA",
                "accuracy": "EXACT_MATCH",
                "ADDRESS": {
                    "street_number": "530",
                    "street_name": "West Main Street",
                    "locality": "Anoka",
                    "admin_2": "Anoka County",
                    "admin_1": "Minnesota",
                    "postal_code": "55303",
                    "country": "United States"
                },
                "LOCATION_DETAILS": {
                    "elevation": "UNAVAILABLE",
                    "timezone_long": "UNAVAILABLE",
                    "timezone_short": "America\/Menominee"
                },
                "COORDINATES": {
                    "latitude": "45.2041251738751",
                    "longitude": "-93.4003513716516"
                },
                "BOUNDARIES": {
                    "northeast_latitude": "45.2041251364687",
                    "northeast_longitude": "-93.4003513351005",
                    "southwest_latitude": "45.2027761197094",
                    "southwest_longitude": "-93.4017002802923"
                }
            }
        ],
        "STATISTICS": {
            "https_ssl": "DISABLED, INSECURE"
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

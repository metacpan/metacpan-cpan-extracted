use warnings;
use Test::More;
use strict;
use IO::String;
use Data::Dumper;

BEGIN {
    require 't/test-lib.pm';
}

sub runTest {
    my ( $name, $configuration, $post_params, $expected ) = @_;
    subtest $name => sub {
        my $client = LLNG::Manager::Test->new( { ini => $configuration } );

        ok(
            my $res = $client->_post(
                '/', { user => "dwho", password => "dwho" },
                %$post_params
            ),
            'Auth query'
        );
        my $id   = expectCookie($res);
        my $data = getSession($id)->data;
        while ( my ( $key, $value ) = each(%$expected) ) {
            is( $data->{$key}, $value, "Session $key is $value" );
        }
    };
}

SKIP: {
    eval "use GeoIP2; use HTTP::BrowserDetect;";
    if ($@) {
        skip 'GeoIP2 / HTTP::BrowserDetect not found', 0;
    }

    runTest(
        "City database, city precision",
        {
            locationDetect               => 1,
            locationDetectIpDetail       => "city",
            locationDetectGeoIpDatabase  => 't/geoip/GeoIP2-City-Test.mmdb',
            locationDetectGeoIpLanguages => 'en, fr',
        },
        {
            ip => "81.2.69.161",
        },
        {
            '_location_detect_env'    => 'mozilla/vms/2643743/GB',
            '_location_detect_env_ip' => 'London (United Kingdom)',
        }
    );

    runTest(
        "City database, city precision, french",
        {
            locationDetect               => 1,
            locationDetectGeoIpDatabase  => 't/geoip/GeoIP2-City-Test.mmdb',
            locationDetectGeoIpLanguages => 'en, fr',
        },
        {
            cookie => "llnglanguage=fr",
            ip     => "81.2.69.161",
        },
        {
            '_location_detect_env'    => 'mozilla/vms/2643743/GB',
            '_location_detect_env_ip' => 'Londres (Royaume-Uni)',
        }
    );

    runTest(
        "City database, city precision, unknown IP",
        {
            locationDetect               => 1,
            locationDetectIpDetail       => "city",
            locationDetectGeoIpDatabase  => 't/geoip/GeoIP2-City-Test.mmdb',
            locationDetectGeoIpLanguages => 'en, fr',
        },
        {
            ip => "1.2.3.4",
        },
        {
            '_location_detect_env'    => 'mozilla/vms/unknown/unknown',
            '_location_detect_env_ip' => 'Unknown (Unknown)',
        }
    );

    runTest(
        "City database, country precision",
        {
            locationDetect               => 1,
            locationDetectIpDetail       => "country",
            locationDetectGeoIpDatabase  => 't/geoip/GeoIP2-City-Test.mmdb',
            locationDetectGeoIpLanguages => 'en, fr',
        },
        {
            ip => "81.2.69.161",
        },
        {
            '_location_detect_env'    => 'mozilla/vms/GB',
            '_location_detect_env_ip' => 'United Kingdom',
        }
    );

    runTest(
        "City database, country precision, unknown IP",
        {
            locationDetect               => 1,
            locationDetectIpDetail       => "country",
            locationDetectGeoIpDatabase  => 't/geoip/GeoIP2-City-Test.mmdb',
            locationDetectGeoIpLanguages => 'en, fr',
        },
        {
            ip => "1.2.3.4",
        },
        {
            '_location_detect_env'    => 'mozilla/vms/unknown',
            '_location_detect_env_ip' => 'Unknown',
        }
    );

    runTest(
        "Country database, country precision",
        {
            locationDetect               => 1,
            locationDetectIpDetail       => "country",
            locationDetectGeoIpDatabase  => 't/geoip/GeoIP2-Country-Test.mmdb',
            locationDetectGeoIpLanguages => 'en, fr',
        },
        {
            ip => "81.2.69.161",
        },
        {
            '_location_detect_env'    => 'mozilla/vms/GB',
            '_location_detect_env_ip' => 'United Kingdom',
        }
    );
    runTest(
        "Country database, city precision",
        {
            locationDetect               => 1,
            locationDetectIpDetail       => "city",
            locationDetectGeoIpDatabase  => 't/geoip/GeoIP2-Country-Test.mmdb',
            locationDetectGeoIpLanguages => 'en, fr',
        },
        {
            ip => "81.2.69.161",
        },
        {
            '_location_detect_env'    => 'mozilla/vms/unknown/GB',
            '_location_detect_env_ip' => 'Unknown (United Kingdom)',
        }
    );
}

clean_sessions();

done_testing();

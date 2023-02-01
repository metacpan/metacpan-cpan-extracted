use Test::More;
use strict;
use IO::String;
use Data::Dumper;

BEGIN {
    require 't/test-lib.pm';
}

SKIP: {
    eval "use GeoIP2; use HTTP::BrowserDetect;";
    if ($@) {
        skip 'GeoIP2 / HTTP::BrowserDetect not found', 0;
    }
    my ( $res, $id, $json );

    my $client = LLNG::Manager::Test->new(
        {
            ini => {
                logLevel                     => 'error',
                authentication               => 'Demo',
                userDB                       => 'Same',
                locationDetect               => 1,
                locationDetectGeoIpDatabase  => 't/geoip/test.mmdb',
                locationDetectGeoIpLanguages => 'en, fr',
                restSessionServer            => 1,
                exportedAttr => '+ mail uid _session_id _location_detect_env'
            }
        }
    );

    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            accept => 'text/html',
            length => 23
        ),
        'Auth query'
    );
    count(1);
    $id = expectCookie($res);

    ok(
        $res = $client->_get(
            '/session/my/global', cookie => "lemonldap=$id"
        ),
        'Get session'
    );
    count(1);
    $json = expectJSON($res);

    ok( $json->{uid} eq 'dwho', 'uid found' ) or explain( $json, "uid='dwho'" );
    ok( $json->{_location_detect_env}, '_location_detect_env found' )
      or explain( $json, "_location_detect_env" );
    ok( scalar keys %$json == 11, '11 exported attributes found' )
      or explain( $json, '11 exported attributes' );
    count(3);

    ok( $client->logout($id), 'Logout' );
    count(1);
}

clean_sessions();

done_testing( count() );

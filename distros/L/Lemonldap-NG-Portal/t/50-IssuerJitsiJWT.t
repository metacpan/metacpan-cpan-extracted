use warnings;
use Test::More;
use strict;
use IO::String;
use Crypt::JWT  qw(decode_jwt);
use Digest::SHA qw(sha256_hex);
use Lemonldap::NG::Portal::Main::Constants ':all';

require 't/test-lib.pm';
require 't/oidc-lib.pm';

my $res;

my $test_ini = {
    logLevel                          => 'error',
    useSafeJail                       => 1,
    issuerDBJitsiMeetTokensActivation => 1,
    issuerDBJitsiMeetTokensRule       => '$uid eq "french"',
    issuerDBJitsiMeetTokensPath       => '^/jitsi/',
    jitsiDefaultServer                => 'http://jitsi.example.com/',
    jitsiAppId                        => "app",
    jitsiSigningAlg                   => "RS256",
    jitsiExpiration                   => 600,
    oidcServicePrivateKeySig          => oidc_key_op_private_sig(),
    oidcServicePublicKeySig           => oidc_cert_op_public_sig(),
    oidcServiceKeyIdSig               => "abc",
    oidcServiceOldKeyIdSig            => "zzzxxx",
    oidcServiceOldPrivateKeySig       => alt_oidc_key_op_private_sig(),
    oidcServiceOldPublicKeySig        => alt_oidc_cert_op_public_sig(),
};

my $client = LLNG::Manager::Test->new( {
        ini => $test_ini,
    }
);

sub testAsapKeyServer {
    my ( $client, $authenticated ) = @_;
    my %extra;

    if ($authenticated) {
        ok(
            $res = $client->_post(
                '/', IO::String->new('user=french&password=french'),
                length => 27
            ),
            'Auth query'
        );
        expectOK($res);
        my $id = expectCookie($res);
        $extra{cookie} = "lemonldap=$id",;
    }

    ok(
        $res = $client->_get(
            '/jitsi/asap/123.pem',
            accept => 'text/html',
            %extra,
        ),
        'ASAP request with unknown key id hash'
    );
    is( $res->[0], 404, "Not found" );

    ok(
        $res = $client->_get(
            '/jitsi/asap/' . sha256_hex('abc') . '.pem',
            accept => 'text/html',
            %extra,
        ),
        'ASAP request with valid key id hash'
    );
    is( $res->[0], 200, "OK" );

    # BEGIN CERTIFICATE / BEGIN RSA PUBLIC KEY are not supported by jitsi
    like( $res->[2]->[0], qr/BEGIN PUBLIC KEY/, "Found correct format" );
    my $key1 = $res->[2]->[0];

    ok(
        $res = $client->_get(
            '/jitsi/asap/' . sha256_hex('zzzxxx') . '.pem',
            accept => 'text/html',
            %extra,
        ),
        'ASAP request with valid key id hash (old key)'
    );
    is( $res->[0], 200, "OK" );
    my $key2 = $res->[2]->[0];

    isnt( $key1, $key2, "Received keys are not the same" );

}

subtest "ASAP key server (PUBLIC KEY)" => sub {
    $client->ini(
        { %$test_ini, oidcServicePublicKeySig => oidc_key_op_public_sig(), } );

    testAsapKeyServer( $client, 0 );
};

subtest "ASAP key server (CERTIFICATE)" => sub {
    $client->ini($test_ini);
    testAsapKeyServer( $client, 0 );
};

subtest "ASAP key server (authenticated)" => sub {
    testAsapKeyServer( $client, 1 );
};

subtest "Unauthorized user" => sub {
    ok(
        $res = $client->_post(
            '/', IO::String->new('user=rtyler&password=rtyler'),
            length => 27
        ),
        'Auth query'
    );
    expectOK($res);
    my $id = expectCookie($res);

    ok(
        $res = $client->_get(
            '/jitsi/login',
            query => {
                room => "abc",
            },
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Jitsi request with good url'
    );
    expectPortalError( $res, PE_UNAUTHORIZEDPARTNER );
};

sub testSuccessfulLogin {
    my ( $client, $jwt_key, $alg ) = @_;
    my $res;

    ok(
        $res = $client->_post(
            '/', IO::String->new('user=french&password=french'),
            length => 27
        ),
        'Auth query'
    );
    expectOK($res);
    my $id = expectCookie($res);

    subtest "Missing room parameter" => sub {

        # Test GET login without room parameter
        ok(
            $res = $client->_get(
                '/jitsi/login',
                cookie => "lemonldap=$id",
                accept => 'text/html'
            ),
            'Jitsi request without room'
        );
        expectPortalError( $res, PE_ERROR );
    };

    subtest "Correct room parameter" => sub {

        # Test GET login
        ok(
            $res = $client->_get(
                '/jitsi/login',
                query => {
                    room => "abc",
                },
                cookie => "lemonldap=$id",
                accept => 'text/html'
            ),
            'Jitsi request with good url'
        );

        my $uri =
          URI->new(
            expectRedirection( $res, qr#(http://jitsi.example.com/.*)# ) );
        is( $uri->path, "/abc", "Correct path" );
        my $jwt = { $uri->query_form }->{jwt};
        ok( $jwt, "Found JWT parameter in response" );

        my ( $header, $jwt_payload ) = decode_jwt(
            token          => $jwt,
            key            => $jwt_key,
            decode_payload => 0,
            decode_header  => 1
        );
        $jwt = from_json($jwt_payload);

        is( $header->{typ}, "JWT", "Correct type in header" );
        is( $header->{alg}, $alg,  "Expected alg" );

        is( $jwt->{sub}, "*",                        "Correct subject/domain" );
        is( $jwt->{aud}, "app",                      "Correct audience" );
        is( $jwt->{iss}, "http://auth.example.com/", "Correct issuer" );
        is( $jwt->{room}, "abc",                     "Correct room" );
        is_deeply(
            $jwt->{context},
            {
                'user' => {
                    'email'       => 'fa@badwolf.org',
                    'id'          => 'french',
                    'name'        => 'Frédéric Accents',
                    'affiliation' => 'owner'
                }
            },
            "Correct user"
        );

        my $exp = $jwt->{exp};
        cmp_ok( $exp - time,
            ">", 500, "Token expires in more than 500 seconds" );
    };
}

subtest "Login with RS256" => sub {
    testSuccessfulLogin( $client, \( oidc_cert_op_public_sig() ), "RS256" );
};

# Update config to use HS256
$client->ini(
    { %$test_ini, jitsiAppSecret => "secret", jitsiSigningAlg => "HS256" } );

subtest "Login with HS256" =>
  sub { testSuccessfulLogin( $client, "secret", "HS256" ) };

clean_sessions();
done_testing();

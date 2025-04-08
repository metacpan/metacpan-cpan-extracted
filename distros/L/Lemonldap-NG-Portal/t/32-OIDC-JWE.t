use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $debug = 'error';
my ( $op, $rp, $res );

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.((?:o|r)p).com(.*)#, ' REST request' );
        my $host = $1;
        my $url  = $2;
        my ( $res, $client );
        count(1);
        if ( $host eq 'op' ) {
            pass("  Request from RP to OP,     endpoint $url");
            $client = $op;
        }
        elsif ( $host eq 'rp' ) {
            pass('  Request from OP to RP');
            $client = $rp;
        }
        else {
            fail('  Aborting REST request (external)');
            return [ 500, [], [] ];
        }
        count(1);
        if ( $req->method =~ /^post$/i ) {
            my $s = $req->content;
            ok(
                $res = $client->_post(
                    $url, IO::String->new($s),
                    length => length($s),
                    type   => $req->header('Content-Type'),
                ),
                '  Execute request'
            );
        }
        else {
            ok(
                $res = $client->_get(
                    $url,
                    (
                        $req->header('Authorization')
                        ? (
                            custom => {
                                HTTP_AUTHORIZATION =>
                                  $req->header('Authorization'),
                            }
                          )
                        : ()
                    ),
                ),
                '  Execute request'
            );
        }
        ok( $res->[0] == 200, '  Response is 200' );
        count(2);
        if ( $url !~ /blogout/ ) {
            ok(
                getHeader( $res, 'Content-Type' ) =~
                  m#^application/(?:json|jwt)#,
                '  Content is JSON'
            ) or explain( $res->[1], 'Content-Type => application/json' );
            count(1);
        }
        return $res;
    }
);

SKIP: {

    eval { require Crypt::JWT };
    if ($@) {
        count(1);
        skip 'Crypt::JWT unavailable', 1;
    }

    # Initialization
    ok( $op = register( 'op', sub { op() } ), 'OP portal' );

    ok(
        $res = $op->_get('/oauth2/jwks'),
        'Get JWKS,     endpoint /oauth2/jwks'
    );
    expectOK($res);
    my $jwks = $res->[2]->[0];

    ok(
        $res = $op->_get('/.well-known/openid-configuration'),
        'Get metadata, endpoint /.well-known/openid-configuration'
    );
    expectOK($res);
    my $metadata = $res->[2]->[0];
    count(3);

    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    ok( $rp = register( 'rp', sub { rp( $jwks, $metadata ) } ), 'RP portal' );
    count(1);

    # Reload OP so it can fetch RP's JWKS
    withHandler( 'op', sub { $op->p->HANDLER->checkConf(1) } );

    # Verify that RP published its keys
    ok( $res = $rp->_get('/oauth2/jwks'), 'RP publish its keys' );
    my $rpKeys = expectJSON($res);
    my $rpEncKey;
    ok( (
                  ref($rpKeys)
              and ref( $rpKeys->{keys} ) eq 'ARRAY'
              and $rpEncKey = $rpKeys->{keys}->[0]
        ),
        'Get RP encryption key'
    );
    count(2);

    # Query RP for auth
    ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth RP request' );
    count(1);
    my ( $url, $query ) =
      expectRedirection( $res,
        qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

    # Push request to OP
    ok( $res = $op->_get( $url, query => $query, accept => 'text/html' ),
        "Push request to OP,         endpoint $url" );
    count(1);
    expectOK($res);

    # Try to authenticate to OP
    $query = "user=french&password=french&$query";
    ok(
        $res = $op->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
        ),
        "Post authentication,        endpoint $url"
    );
    count(1);
    my $idpId = expectCookie($res);
    my ( $host, $tmp );
    ( $host, $tmp, $query ) = expectForm( $res, '#', undef, 'confirm' );

    ok(
        $res = $op->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
            length => length($query),
        ),
        "Post confirmation,          endpoint $url"
    );
    count(1);

    ($query) = expectRedirection( $res, qr#^http://auth.rp.com/?\?(.*)$# );

    # Push OP response to RP

    ok( $res = $rp->_get( '/', query => $query, accept => 'text/html' ),
        'Call openidconnectcallback on RP' );
    count(1);
    my $spId = expectCookie($res);

    # Logout initiated by OP

    # Reset conf to make sure lazy loading works during logout (#3014)
    withHandler( 'op', sub { $op->p->HANDLER->checkConf(1) } );

    ok(
        $res = $op->_get(
            '/',
            query  => 'logout',
            cookie => "lemonldap=$idpId",
            accept => 'text/html'
        ),
        'Query OP for logout'
    );

    count(1);
    expectOK($res);

    # Test if logout is done
    ok(
        $res = $op->_get(
            '/', cookie => "lemonldap=$idpId",
        ),
        'Test if user is reject on OP'
    );
    count(1);
    expectReject($res);

    ok(
        $res = $rp->_get(
            '/',
            cookie => "lemonldap=$spId",
            accept => 'text/html'
        ),
        'Test if user is reject on RP'
    );
    count(1);
    expectRedirection( $res, qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );
}

clean_sessions();
done_testing( count() );

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'idp.com',
                portal                          => 'http://auth.op.com/',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => "1",
                oidcRPMetaDataExportedVars      => {
                    rp => {
                        email       => "mail",
                        family_name => "cn",
                        name        => "cn"
                    }
                },
                oidcServiceAllowHybridFlow            => 1,
                oidcServiceAllowImplicitFlow          => 1,
                oidcServiceAllowAuthorizationCodeFlow => 1,
                oidcRPMetaDataOptions                 => {
                    rp => {
                        oidcRPMetaDataOptionsDisplayName  => "RP",
                        oidcRPMetaDataOptionsClientID     => "rpid",
                        oidcRPMetaDataOptionsClientSecret => "rpsecret",
                        oidcRPMetaDataOptionsAccessTokenEncKeyMgtAlg =>
                          'RSA-OAEP',
                        oidcRPMetaDataOptionsIDTokenExpiration    => 3600,
                        oidcRPMetaDataOptionsIDTokenSignAlg       => "HS512",
                        oidcRPMetaDataOptionsIdTokenEncKeyMgtAlg  => 'RSA-OAEP',
                        oidcRPMetaDataOptionsBypassConsent        => 0,
                        oidcRPMetaDataOptionsUserIDAttr           => "",
                        oidcRPMetaDataOptionsUserInfoSignAlg      => 'RS256',
                        oidcRPMetaDataOptionsUserInfoEncKeyMgtAlg => 'RSA-OAEP',
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsLogoutUrl             =>
                          'http://auth.rp.com/oauth2/blogout',
                        oidcRPMetaDataOptionsLogoutType            => 'back',
                        oidcRPMetaDataOptionsLogoutSessionRequired => 1,
                        oidcRPMetaDataOptionsLogoutEncKeyMgtAlg => 'RSA-OAEP',
                        oidcRPMetaDataOptionsRedirectUris       =>
                          'http://auth.rp.com/?openidconnectcallback=1',

                        # If both JWKS URI & document are set, document is used
                        oidcRPMetaDataOptionsJwksUri =>
                          'http://auth.rp.com/oauth2/badjwks',
                        oidcRPMetaDataOptionsJwks =>
'{"keys":[{"x5t":"4Pims8kl3DEgB2ld9pmvz9svAxo","kid":"aabbcc","e":"AQAB","n":"s2jsmIoFuWzMkilJaA8__5_T30cnuzX9GImXUrFR2k9EKTMtGMHCdKlWOl3BV-BTAU9TLz7Jzd_iJ5GJ6B8TrH1PHFmHpy8_qE_S5OhinIpIi7ebABqnoVcwDdCa8ugzq8k8SWxhRNXfVIlwz4NH1caJ8lmiERFj7IvNKqEhzAk0pyDr8hubveTC39xREujKlsqutpPAFPJ3f2ybVsdykX5rx0h5SslG3jVWYhZ_SOb2aIzOr0RMjhQmsYRwbpt3anjlBZ98aOzg7GAkbO8093X5VVk9vaPRg0zxJQ0Do0YLyzkRisSAIFb0tdKuDnjRGK6y_N2j6At2HjkxntbtGQ","use":"enc","kty":"RSA","alg":"RSA-OAEP","x5c":["MIIC/zCCAeegAwIBAgIUYFySF9bmkPZK1u+wdkwTSS9bxnMwDQYJKoZIhvcNAQELBQAwDzENMAsGA1UEAwwEVGVzdDAeFw0yMjExMjkxNDI2MTFaFw00MjAxMjgxNDI2MTFaMA8xDTALBgNVBAMMBFRlc3QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCzaOyYigW5bMySKUloDz//n9PfRye7Nf0YiZdSsVHaT0QpMy0YwcJ0qVY6XcFX4FMBT1MvPsnN3+InkYnoHxOsfU8cWYenLz+oT9Lk6GKcikiLt5sAGqehVzAN0Jry6DOryTxJbGFE1d9UiXDPg0fVxonyWaIREWPsi80qoSHMCTSnIOvyG5u95MLf3FES6MqWyq62k8AU8nd/bJtWx3KRfmvHSHlKyUbeNVZiFn9I5vZojM6vREyOFCaxhHBum3dqeOUFn3xo7ODsYCRs7zT3dflVWT29o9GDTPElDQOjRgvLORGKxIAgVvS10q4OeNEYrrL83aPoC3YeOTGe1u0ZAgMBAAGjUzBRMB0GA1UdDgQWBBS/LX4E0Ipqh/4wcxNIXvoksj4vizAfBgNVHSMEGDAWgBS/LX4E0Ipqh/4wcxNIXvoksj4vizAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQAZk2m++tQ/FkZedpoABlbRjvWjQ8u6qH5zaqS5oxnNX/JfJEFOsqL2n37g/0wuu6HhSYh2vD+zc4KfVMrjv6wzzmspJaZnACQLlEoB+ZKC1P+a8R95BK8iL1Dp1Iy0SC8CR6ZvQDEHNGWm8SACK/cm2ee4wv4obg336SjXZ+Wid8lmdKDpJ7/XjiK2NQuvDLw6Jt7QpItKqwajEcJ/BOYQi7AAYtRBfi0v99nm3L2XF2ijTsIHDGhQqliFTXYwKO6ErCevEpDfDF28txqTR333fBH0ADco70lNPVTfOtpfdTjKvJ3N9SmU9V0BbhtegzMeung3QBmtMxApt8++LcJp"]}]}',
                    }
                },
                oidcOPMetaDataOptions           => {},
                oidcOPMetaDataJSON              => {},
                oidcOPMetaDataJWKS              => {},
                oidcServiceMetaDataAuthnContext => {
                    'loa-4' => 4,
                    'loa-1' => 1,
                    'loa-5' => 5,
                    'loa-2' => 2,
                    'loa-3' => 3
                },
                oidcServicePrivateKeySig => oidc_key_op_private_sig,
                oidcServicePublicKeySig  => oidc_cert_op_public_sig,
            }
        }
    );
}

sub rp {
    my ( $jwks, $metadata ) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $debug,
                domain                     => 'rp.com',
                portal                     => 'http://auth.rp.com/',
                authentication             => 'OpenIDConnect',
                userDB                     => 'Same',
                restSessionServer          => 1,
                oidcOPMetaDataExportedVars => {
                    op => {
                        cn   => "name",
                        uid  => "sub",
                        sn   => "family_name",
                        mail => "email"
                    }
                },
                oidcServiceMetaDataBackChannelURI => 'blogout',
                oidcOPMetaDataOptions             => {
                    op => {
                        oidcOPMetaDataOptionsCheckJWTSignature => 1,
                        oidcOPMetaDataOptionsJWKSTimeout       => 0,
                        oidcOPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcOPMetaDataOptionsScope        => "openid profile",
                        oidcOPMetaDataOptionsStoreIDToken => 0,
                        oidcOPMetaDataOptionsDisplay      => "",
                        oidcOPMetaDataOptionsClientID     => "rpid",
                        oidcOPMetaDataOptionsConfigurationURI =>
"https://auth.op.com/.well-known/openid-configuration",
                    }
                },
                oidcServicePrivateKeyEnc => oidc_key_op_private_sig,
                oidcServicePublicKeyEnc  => oidc_cert_op_public_sig,
                oidcServiceKeyIdEnc      => 'aabbcc',
                oidcOPMetaDataJWKS       => {
                    op => $jwks,
                },
                oidcOPMetaDataJSON => {
                    op => $metadata,
                }
            }
        }
    );
}

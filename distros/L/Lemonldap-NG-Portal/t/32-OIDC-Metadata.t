use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use Hash::Merge::Simple qw/merge/;
use JSON;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $debug = 'error';

sub getop {
    my ($options) = @_;
    return LLNG::Manager::Test->new( {
            ini => merge {
                logLevel                        => $debug,
                domain                          => 'idp.com',
                portal                          => 'http://auth.op.com',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => 1,
                oidcRPMetaDataExportedVars      => {
                    rp => {
                        email       => "mail",
                        family_name => "cn",
                        name        => "cn"
                    },
                },
                oidcServiceAllowHybridFlow            => 1,
                oidcServiceAllowImplicitFlow          => 1,
                oidcServiceAllowAuthorizationCodeFlow => 1,
                oidcRPMetaDataOptions                 => {
                    rp => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsBypassConsent         => 1,
                    },
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
            },
            $options
        },
    );
}

subtest "OpenID Connect metadata", sub {
    my $op = getop();

    # Get Metadata
    my $res = expectJSON(
        $op->_get(
            "/.well-known/openid-configuration", accept => 'text/html',
        )
    );

    my $jwks_uri = $res->{jwks_uri};
    is( $jwks_uri, 'http://auth.op.com/oauth2/jwks', 'Correct JWKS URI' );
};

subtest "JWKS test (certificate)", sub {
    my $op  = getop();
    my $res = expectJSON(
        $op->_get(
            "/oauth2/jwks", accept => 'text/html',
        )
    );
    my $key = $res->{keys}->[0];
    is( $key->{e}, 'AQAB', 'Correct RSA exponent' );
    is(
        $key->{n},
's2jsmIoFuWzMkilJaA8__5_T30cnuzX9GImXUrFR2k9EKTMtGMHCdKlWOl3BV-BTAU9TLz7Jzd_iJ5GJ6B8TrH1PHFmHpy8_qE_S5OhinIpIi7ebABqnoVcwDdCa8ugzq8k8SWxhRNXfVIlwz4NH1caJ8lmiERFj7IvNKqEhzAk0pyDr8hubveTC39xREujKlsqutpPAFPJ3f2ybVsdykX5rx0h5SslG3jVWYhZ_SOb2aIzOr0RMjhQmsYRwbpt3anjlBZ98aOzg7GAkbO8093X5VVk9vaPRg0zxJQ0Do0YLyzkRisSAIFb0tdKuDnjRGK6y_N2j6At2HjkxntbtGQ',
        'Correct RSA modulus'
    );
    is( $key->{kty}, 'RSA', 'Correct key type' );
    is( $key->{use}, 'sig', 'Correct key use' );
    is(
        $key->{x5c}->[0],
'MIIC/zCCAeegAwIBAgIUYFySF9bmkPZK1u+wdkwTSS9bxnMwDQYJKoZIhvcNAQELBQAwDzENMAsGA1UEAwwEVGVzdDAeFw0yMjExMjkxNDI2MTFaFw00MjAxMjgxNDI2MTFaMA8xDTALBgNVBAMMBFRlc3QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCzaOyYigW5bMySKUloDz//n9PfRye7Nf0YiZdSsVHaT0QpMy0YwcJ0qVY6XcFX4FMBT1MvPsnN3+InkYnoHxOsfU8cWYenLz+oT9Lk6GKcikiLt5sAGqehVzAN0Jry6DOryTxJbGFE1d9UiXDPg0fVxonyWaIREWPsi80qoSHMCTSnIOvyG5u95MLf3FES6MqWyq62k8AU8nd/bJtWx3KRfmvHSHlKyUbeNVZiFn9I5vZojM6vREyOFCaxhHBum3dqeOUFn3xo7ODsYCRs7zT3dflVWT29o9GDTPElDQOjRgvLORGKxIAgVvS10q4OeNEYrrL83aPoC3YeOTGe1u0ZAgMBAAGjUzBRMB0GA1UdDgQWBBS/LX4E0Ipqh/4wcxNIXvoksj4vizAfBgNVHSMEGDAWgBS/LX4E0Ipqh/4wcxNIXvoksj4vizAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQAZk2m++tQ/FkZedpoABlbRjvWjQ8u6qH5zaqS5oxnNX/JfJEFOsqL2n37g/0wuu6HhSYh2vD+zc4KfVMrjv6wzzmspJaZnACQLlEoB+ZKC1P+a8R95BK8iL1Dp1Iy0SC8CR6ZvQDEHNGWm8SACK/cm2ee4wv4obg336SjXZ+Wid8lmdKDpJ7/XjiK2NQuvDLw6Jt7QpItKqwajEcJ/BOYQi7AAYtRBfi0v99nm3L2XF2ijTsIHDGhQqliFTXYwKO6ErCevEpDfDF28txqTR333fBH0ADco70lNPVTfOtpfdTjKvJ3N9SmU9V0BbhtegzMeung3QBmtMxApt8++LcJp',
        'Correct certificate'
    );
    is( $key->{x5t}, '4Pims8kl3DEgB2ld9pmvz9svAxo',
        'Correct certificate thumbprint' );
};

subtest "JWKS test (pubkey)", sub {

    # JWKS test (key)
    my $op  = getop( { oidcServicePublicKeySig => oidc_key_op_public_sig } );
    my $res = expectJSON(
        $op->_get(
            "/oauth2/jwks", accept => 'text/html',
        )
    );
    my $key = $res->{keys}->[0];
    is( $key->{e}, 'AQAB', 'Correct RSA exponent' );
    is(
        $key->{n},
's2jsmIoFuWzMkilJaA8__5_T30cnuzX9GImXUrFR2k9EKTMtGMHCdKlWOl3BV-BTAU9TLz7Jzd_iJ5GJ6B8TrH1PHFmHpy8_qE_S5OhinIpIi7ebABqnoVcwDdCa8ugzq8k8SWxhRNXfVIlwz4NH1caJ8lmiERFj7IvNKqEhzAk0pyDr8hubveTC39xREujKlsqutpPAFPJ3f2ybVsdykX5rx0h5SslG3jVWYhZ_SOb2aIzOr0RMjhQmsYRwbpt3anjlBZ98aOzg7GAkbO8093X5VVk9vaPRg0zxJQ0Do0YLyzkRisSAIFb0tdKuDnjRGK6y_N2j6At2HjkxntbtGQ',
        'Correct RSA modulus'
    );
    is( $key->{kty}, 'RSA', 'Correct key type' );
    is( $key->{use}, 'sig', 'Correct key use' );
};

clean_sessions();
done_testing();


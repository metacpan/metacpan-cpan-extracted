use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use JSON;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $debug = 'error';

sub Lemonldap::NG::Portal::Auth::Demo::authnLevel {
    return 3;
}

# Initialization
my $op = LLNG::Manager::Test->new( {
        ini => {
            logLevel                        => $debug,
            domain                          => 'idp.com',
            portal                          => 'http://auth.op.com/',
            authentication                  => 'Demo',
            userDB                          => 'Same',
            issuerDBOpenIDConnectActivation => 1,
            issuerDBOpenIDConnectRule       => '$uid eq "french"',
            oidcRPMetaDataExportedVars      => {
                rp => {
                    email       => "mail",
                    family_name => "cn",
                    name        => "cn"
                },
                rp2 => {
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
                    oidcRPMetaDataOptionsDisplayName           => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rpid",
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rpsecret",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRedirectUris => 'http://rp.com/',
                    oidcRPMetaDataOptionsAuthnLevel   => 2,
                },
                rp2 => {
                    oidcRPMetaDataOptionsDisplayName           => "RP2",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rp2id",
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rp2secret",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRule         => '$uid eq "dwho"',
                    oidcRPMetaDataOptionsRedirectUris => 'http://rp2.com/',
                },
                rp_denied => {
                    oidcRPMetaDataOptionsDisplayName           => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rpdeniedid",
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rpsecret",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRedirectUris => 'http://rpdenied.com/',
                    oidcRPMetaDataOptionsAuthnLevel   => 9,
                },
            },
            oidcOPMetaDataOptions           => {},
            oidcOPMetaDataJSON              => {},
            oidcOPMetaDataJWKS              => {},
            oidcServiceMetaDataAuthnContext => {
                'loa-1' => 1,
                'loa-2' => 2,
                'loa-3' => 3,
                'loa-4' => 4,
                'loa-5' => 5,
            },
            oidcServicePrivateKeySig => oidc_key_op_private_sig,
            oidcServicePublicKeySig  => oidc_cert_op_public_sig,
        }
    }
);
my ( $res, $code, $token );

# Authenticate to LLNG
my $url   = "/";
my $query = "user=french&password=french";
ok(
    $res = $op->_post(
        "/",
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
    ),
    "Post authentication"
);
count(1);
my $idpId = expectCookie($res);

subtest "Try to increase the required authn level with acr_values" => sub {
    $res = authorize(
        $op, $idpId,
        {
            response_type => "code",
            scope         => "openid",
            client_id     => "rpid",
            redirect_uri  => "http://rp.com/",
        }
    );
    ok( expectRedirection( $res, qr#http://.*code=([^\&]*)# ),
        "Access was allowed" );

    $res = authorize(
        $op, $idpId,
        {
            response_type => "code",
            scope         => "openid",
            client_id     => "rpid",
            acr_values    => "unknown loa-3 loa-4",
            redirect_uri  => "http://rp.com/",
        }
    );
    ok( expectRedirection( $res, qr#http://.*code=([^\&]*)# ),
        "Access was allowed" );

    $res = authorize(
        $op, $idpId,
        {
            response_type => "code",
            scope         => "openid",
            client_id     => "rpid",
            acr_values    => "unknown loa-4 loa-3",
            redirect_uri  => "http://rp.com/",
        }
    );
    expectForm( $res, undef, '/upgradesession' );
};

subtest "acr_values correctly sets target AuthnLevel" => sub {
    $res = authorize(
        $op, undef,
        {
            response_type => "code",
            scope         => "openid",
            client_id     => "rpid",
            redirect_uri  => "http://rp.com/",
        }
    );
    is( expectPdata($res)->{targetAuthnLevel},
        2, "No LOA, correct target Authnlevel" );

    $res = authorize(
        $op, undef,
        {
            response_type => "code",
            scope         => "openid",
            acr_values    => "unknown loa-4 loa-3",
            client_id     => "rpid",
            redirect_uri  => "http://rp.com/",
        }
    );
    is( expectPdata($res)->{targetAuthnLevel},
        4, "LOA specified, correct target Authnlevel" );

};

subtest "Try to lower the required authn level with acr_values" => sub {
    $res = authorize(
        $op, $idpId,
        {
            response_type => "code",
            scope         => "openid",
            client_id     => "rpdeniedid",
            redirect_uri  => "http://rpdenied.com/",
        }
    );
    expectForm( $res, undef, '/upgradesession' );

    $res = authorize(
        $op, $idpId,
        {
            response_type => "code",
            scope         => "openid",
            client_id     => "rpdeniedid",
            acr_values    => "loa-1",
            redirect_uri  => "http://rpdenied.com/",
        }
    );
    expectForm( $res, undef, '/upgradesession' );
};

subtest "Try to get code for RP1 with invalide scope name" => sub {
    $query =
"response_type=code&scope=openid%20profile%20email%22&client_id=rpid&state=af0ifjsldkj&redirect_uri=http%3A%2F%2Frp.com%2F";
    ok(
        $res = $op->_get(
            "/oauth2/authorize",
            query  => "$query",
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
        ),
        "Get authorization code for rp1"
    );
    count(1);
    expectPortalError( $res, 24, "Invalid scope" );
};

subtest "Use code on different RP" => sub {
    #
    # Get code for RP1
    $query =
"response_type=code&scope=openid%20profile%20email&client_id=rpid&state=af0ifjsldkj&redirect_uri=http%3A%2F%2Frp.com%2F";
    ok(
        $res = $op->_get(
            "/oauth2/authorize",
            query  => "$query",
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
        ),
        "Get authorization code for rp1"
    );
    count(1);

    ($code) = expectRedirection( $res, qr#http://rp\.com/.*code=([^\&]*)# );

    # Play code on RP2
    $query = buildForm( {
            grant_type   => 'authorization_code',
            code         => $code,
            redirect_uri => 'http://rp2.com/',
        }
    );

    ok(
        $res = $op->_post(
            "/oauth2/token",
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            custom => {
                HTTP_AUTHORIZATION => "Basic "
                  . encode_base64("rp2id:rp2secret"),
            },
        ),
        "Post token on wrong RP"
    );
    count(1);

    # Expect an invalid request
    expectReject( $res, 400, "invalid_grant" );

    is( getHeader( $res, "Access-Control-Allow-Origin" ),
        "*", "CORS header present on Token error response" );
    count(1);
};

subtest "Test authentication failures in token grant" => sub {

    # Get new code for RP1
    $query =
"response_type=code&scope=openid%20profile%20email&client_id=rpid&state=af0ifjsldkj&redirect_uri=http%3A%2F%2Frp.com%2F";
    ok(
        $res = $op->_get(
            "/oauth2/authorize",
            query  => "$query",
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
        ),
        "Get authorization code again"
    );
    count(1);

    ($code) = expectRedirection( $res, qr#http://rp\.com/.*code=([^\&]*)# );

    # Play code on RP1
    $query = buildForm( {
            grant_type   => 'authorization_code',
            code         => $code,
            redirect_uri => 'http://rp.com/',
        }
    );

    # Bad auth (header)
    ok(
        $res = $op->_post(
            "/oauth2/token",
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            custom => {
                HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid:invalid"),
            },
        ),
        "Post auth code on correct RP"
    );
    count(1);
    expectReject( $res, 401, "invalid_client" );
    is( getHeader( $res, "WWW-Authenticate" ), "Basic" );
    count(1);

    # Bad auth (header)
    ok(
        $res = $op->_post(
            "/oauth2/token",
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            custom => {
                HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid:"),
            },
        ),
        "Post auth code on correct RP"
    );
    count(1);
    expectReject( $res, 401, "invalid_client" );
    is( getHeader( $res, "WWW-Authenticate" ), "Basic" );
    count(1);

    # Bad auth (form) - invalid client secret
    $query = buildForm( {
            grant_type    => 'authorization_code',
            code          => $code,
            redirect_uri  => 'http://rp.com/',
            client_id     => 'rpid',
            client_secret => 'rpsecre',
        }
    );

    ok(
        $res = $op->_post(
            "/oauth2/token",
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
        ),
        "Post auth code on correct RP"
    );
    count(1);
    expectReject( $res, 400, "invalid_client" );
    is( getHeader( $res, "WWW-Authenticate" ), undef );
    count(1);

    subtest "Bad auth (form) - missing client secret" => sub {
        ok(
            $res = $op->_post(
                "/oauth2/token",
                {
                    grant_type   => 'authorization_code',
                    code         => $code,
                    redirect_uri => 'http://rp.com/',
                    client_id    => 'rpid',
                },
                accept => 'text/html',
            ),
            "Post auth code on correct RP"
        );
        count(1);
        expectReject( $res, 400, "invalid_client" );
        is( getHeader( $res, "WWW-Authenticate" ), undef );
        count(1);
    };

    # Correct parameters
    $query = buildForm( {
            grant_type    => 'authorization_code',
            code          => $code,
            redirect_uri  => 'http://rp.com/',
            client_id     => 'rpid',
            client_secret => 'rpsecret',
        }
    );

    # Authenticated client with two methods at once (#2474)
    ok(
        $res = $op->_post(
            "/oauth2/token",
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            custom => {
                HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid:rpsecret"),
            },
        ),
        "Post auth code on correct RP"
    );
    count(1);
    expectReject( $res, 401, "invalid_client" );
    is( getHeader( $res, "WWW-Authenticate" ), "Basic" );
    count(1);

    # Try to supply client_secret as GET parameter
    ok(
        $res = $op->_get(
            "/oauth2/token",
            query  => $query,
            accept => 'text/html',
        ),
        "Use GET on token endpoint"
    );
    count(1);
    expectReject( $res, 400, "invalid_client" );

    ok(
        $res = $op->_post(
            "/oauth2/token",
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
        ),
        "Post auth code on correct RP"
    );
    count(1);

    is( getHeader( $res, "Access-Control-Allow-Origin" ),
        "*", "CORS header present on Token response" );
    count(1);

    $res = expectJSON($res);
    ok( $token = $res->{access_token}, 'Access token present' );
    count(1);

    ok(
        $res = $op->_post(
            "/oauth2/userinfo",
            IO::String->new(""),
            accept => 'text/html',
            length => 0,
            custom => {
                HTTP_AUTHORIZATION => "Bearer " . $token,
            },
        ),
        "post to userinfo",
    );
    count(1);
    ok( $res->[0] == 200, "Userinfo successful" );
    count(1);

    is( getHeader( $res, "Access-Control-Allow-Origin" ),
        "*", "CORS header present on userinfo response" );
    count(1);

};

subtest "Use expired access token" => sub {
    Time::Fake->offset("+2h");
    ok(
        $res = $op->_post(
            "/oauth2/userinfo",
            IO::String->new(""),
            accept => 'text/html',
            length => 0,
            custom => {
                HTTP_AUTHORIZATION => "Bearer " . $token,
            },
        ),
        "post to userinfo with expired access token"
    );
    count(1);
    ok( $res->[0] == 401, "Access denied with expired token" );
    count(1);

    is( getHeader( $res, "Access-Control-Allow-Origin" ),
        "*", "CORS header present on userinfo error response" );
    count(1);
};

clean_sessions();
done_testing();


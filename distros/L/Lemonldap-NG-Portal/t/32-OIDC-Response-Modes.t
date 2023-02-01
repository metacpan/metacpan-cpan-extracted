use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use JSON;
use URI;
use URI::QueryParam;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $debug = 'error';

# Initialization
my $op = LLNG::Manager::Test->new( {
        ini => {
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
                    oidcRPMetaDataOptionsDisplayName           => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rpid",
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rpsecret",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRedirectUris => "http://rp.com/",
                },
            },
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

sub fragmentGetParam {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($res) = @_;

    my ($uri) = expectRedirection( $res, qr,(.*), );
    $uri = URI->new($uri);
    ok( $uri->fragment, "Fragment found" );
    ok( !$uri->query,   "Query is empty" );

    #Copy fragment into query so we can extract it as a hash
    $uri->query( $uri->fragment );
    my $params = $uri->query_form_hash;

    return ( $uri, $params );
}

sub queryGetParam {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($res) = @_;

    my ($uri) = expectRedirection( $res, qr,(.*), );
    $uri = URI->new($uri);
    ok( $uri->query, "Query found" );

    my $params = $uri->query_form_hash;

    return ( $uri, $params );
}

sub postGetParam {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($res) = @_;

    my ( $host, $url, $query ) = expectForm($res);
    my $uri = URI->new("http://$host");
    $uri->path_query($url);

    # Use temp URI to parse POST fields into a hashref
    my $tmp = URI->new;
    $tmp->query($query);
    my $params = $tmp->query_form_hash;

    return ( $uri, $params );
}

sub validateSuccessParam {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $uri, $params, $asserted_params ) = @_;
    is( $uri->host,       "rp.com",      "Correct host" );
    is( $uri->path,       "/",           "Correct path" );
    is( $params->{state}, 'af0ifjsldkj', "Correct state" );
    for (@$asserted_params) {
        ok( $params->{$_}, "Found $_" );
    }
}

sub validateErrorParam {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $uri, $params ) = @_;
    is( $uri->host, "rp.com", "Correct host" );
    is( $uri->path, "/",      "Correct path" );
    ok( $params->{error}, "Found error" );
    is( $params->{state}, 'af0ifjsldkj', "Correct state" );
}

sub queryResponseMode {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $param ) = @_;
    validateSuccessParam( queryGetParam($res), $param );
}

sub queryResponseModeError {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $param ) = @_;
    validateErrorParam( queryGetParam($res), $param );
}

sub fragmentResponseMode {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $param ) = @_;
    validateSuccessParam( fragmentGetParam($res), $param );
}

sub fragmentResponseModeError {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $param ) = @_;
    validateErrorParam( fragmentGetParam($res), $param );
}

sub formPostResponseMode {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $param ) = @_;
    validateSuccessParam( postGetParam($res), $param );
}

my $res;

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

my $idpId = expectCookie($res);

# Tests:
# hybrid flow: only fragment or form_post
# implicit: only fragment or form_post
# authcode: all, default query

subtest "Default response mode for Authorization Code grant" => sub {
    my $res = authorize(
        $op, $idpId,
        {
            response_type => 'code',
            scope         => 'openid profile email',
            client_id     => 'rpid',
            state         => 'af0ifjsldkj',
            redirect_uri  => 'http://rp.com/',
        }
    );
    queryResponseMode($res);
};

subtest "Fragment response mode for Authorization Code grant" => sub {
    my $res = authorize(
        $op, $idpId,
        {
            response_type => 'code',
            response_mode => 'fragment',
            scope         => 'openid profile email',
            client_id     => 'rpid',
            state         => 'af0ifjsldkj',
            redirect_uri  => 'http://rp.com/',
        }
    );
    fragmentResponseMode( $res, ["code"] );
};

subtest "Form POST response mode for Authorization Code grant" => sub {
    my $res = authorize(
        $op, $idpId,
        {
            response_type => 'code',
            response_mode => 'form_post',
            scope         => 'openid profile email',
            client_id     => 'rpid',
            state         => 'af0ifjsldkj',
            redirect_uri  => 'http://rp.com/',
        }
    );
    formPostResponseMode( $res, ["code"] );
};

subtest "Default response mode for Implicit grant" => sub {
    my $res = authorize(
        $op, $idpId,
        {
            response_type => 'id_token token',
            scope         => 'openid profile email',
            client_id     => 'rpid',
            state         => 'af0ifjsldkj',
            nonce         => 123,
            redirect_uri  => 'http://rp.com/',
        }
    );
    fragmentResponseMode( $res, [ "id_token", "access_token" ] );
};

subtest "Query response mode for Implicit grant" => sub {
    my $res = authorize(
        $op, $idpId,
        {
            response_type => 'id_token token',
            response_mode => 'query',
            scope         => 'openid profile email',
            client_id     => 'rpid',
            state         => 'af0ifjsldkj',
            nonce         => 123,
            redirect_uri  => 'http://rp.com/',
        }
    );
    expectPortalError( $res, 24 );
};

subtest "Form POST response mode for Implicit grant" => sub {
    my $res = authorize(
        $op, $idpId,
        {
            response_type => 'id_token token',
            response_mode => 'form_post',
            scope         => 'openid profile email',
            client_id     => 'rpid',
            state         => 'af0ifjsldkj',
            nonce         => 123,
            redirect_uri  => 'http://rp.com/',
        }
    );
    formPostResponseMode( $res, [ "id_token", "access_token" ] );
};

subtest "Default response mode for Hybrid grant" => sub {
    my $res = authorize(
        $op, $idpId,
        {
            response_type => 'code id_token',
            scope         => 'openid profile email',
            client_id     => 'rpid',
            state         => 'af0ifjsldkj',
            nonce         => 123,
            redirect_uri  => 'http://rp.com/',
        }
    );
    fragmentResponseMode( $res, [ "id_token", "code" ] );
};

subtest "Query response mode for Hybrid grant" => sub {
    my $res = authorize(
        $op, $idpId,
        {
            response_type => 'code id_token',
            response_mode => 'query',
            scope         => 'openid profile email',
            client_id     => 'rpid',
            state         => 'af0ifjsldkj',
            nonce         => 123,
            redirect_uri  => 'http://rp.com/',
        }
    );
    expectPortalError( $res, 24 );
};

subtest "Form POST response mode for Hybrid grant" => sub {
    my $res = authorize(
        $op, $idpId,
        {
            response_type => 'code id_token',
            response_mode => 'form_post',
            scope         => 'openid profile email',
            client_id     => 'rpid',
            state         => 'af0ifjsldkj',
            nonce         => 123,
            redirect_uri  => 'http://rp.com/',
        }
    );
    formPostResponseMode( $res, [ "id_token", "code" ] );
};

clean_sessions();
done_testing();

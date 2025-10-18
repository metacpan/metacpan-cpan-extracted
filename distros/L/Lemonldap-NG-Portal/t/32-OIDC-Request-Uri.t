use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use Plack::Request;
use Plack::Response;
use MIME::Base64;

# Initialization
my ( $op, $res );
ok( $op = op(), 'OP portal' );

my $i = $op->p->loadedModules->{'Lemonldap::NG::Portal::Issuer::OpenIDConnect'};

# Lazy load client
#$i->getRP("rpid");

our $call_allowed = 1;

LWP::Protocol::PSGI->register(
    sub {
        my $req     = Plack::Request->new(@_);
        my $payload = {
            client_id    => "rpid",
            redirect_uri => "http://redirect.uri/"
        };

        is( $req->uri->host, "request.uri", "only authorized URI is called" );
        ok( $call_allowed, "Call is expected in this scenario" );

        if ( $req->path_info eq "/baduri" ) {
            $payload->{redirect_uri} = "http://invalid/";
        }
        if ( $req->path_info eq "/badclientid" ) {
            $payload->{client_id} = "otherid";
        }
        my $res = Plack::Response->new(200);
        $res->content_type('application/json');
        $res->body( $i->createJWT( $payload, "HS256", "rp" ) );
        return $res->finalize;
    }
);

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $debug = 'error';

subtest "Successful request" => sub {
    my $idpId = login( $op, "french" );
    $res = authorize(
        $op, $idpId,
        {
            response_type => "code",
            client_id     => "rpid",
            scope         => "openid",
            state         => "xxyy",
            request_uri   => "http://request.uri/valid"
        }
    );
    expectRedirection( $res, qr,http://redirect.uri/.*state=xxyy.*, );
};

subtest "Successful request, override of bad redirect_uri" => sub {
    my $idpId = login( $op, "french" );
    $res = authorize(
        $op, $idpId,
        {
            response_type => "code",
            client_id     => "rpid",
            scope         => "openid",
            redirect_uri  => "http://bad.uri/",
            request_uri   => "http://request.uri/valid"
        }
    );
    expectRedirection( $res, qr,http://redirect.uri/.*, );
};

subtest "unauthorized Request URI" => sub {
    my $idpId = login( $op, "french" );
    local $call_allowed = 0;
    $res = authorize(
        $op, $idpId,
        {
            response_type => "code",
            client_id     => "rpid",
            scope         => "openid",
            request_uri   => "http://bad.uri/"
        }
    );
    expectPortalError( $res, 24 );
};

subtest "Allowed request URI, bad redirect URI" => sub {
    my $idpId = login( $op, "french" );
    $res = authorize(
        $op, $idpId,
        {
            response_type => "code",
            client_id     => "rpid",
            scope         => "openid",
            request_uri   => "http://request.uri/baduri"
        }
    );
    expectPortalError( $res, 108 );
};

subtest "Allowed request URI, bad redirect URI override" => sub {
    my $idpId = login( $op, "french" );
    $res = authorize(
        $op, $idpId,
        {
            response_type => "code",
            client_id     => "rpid",
            scope         => "openid",
            redirect_uri  => "http://redirect.uri/",
            request_uri   => "http://request.uri/baduri"
        }
    );
    expectPortalError( $res, 108 );
};

subtest "Undeclared request_uri is not called before auth" => sub {
    local $call_allowed = 0;
    $res = authorize(
        $op, undef,
        {
            response_type => "code",
            client_id     => "rpid",
            scope         => "openid",
            request_uri   => "http://bad.uri/valid"
        }
    );

    # LWP PSGI handler above will fail the test if a call is performed
    ok(1);
};

clean_sessions();
done_testing();

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'idp.com',
                portal                          => 'http://auth.op.com/',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => 1,
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
                        oidcRPMetaDataOptionsDisplayName           => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                        oidcRPMetaDataOptionsClientID              => "rpid",
                        oidcRPMetaDataOptionsClientSecret          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg        => "RS256",
                        oidcRPMetaDataOptionsBypassConsent         => 0,
                        oidcRPMetaDataOptionsUserIDAttr            => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsBypassConsent         => 1,
                        oidcRPMetaDataOptionsRequestUris           =>
                          "http://request.uri/*",
                        oidcRPMetaDataOptionsRedirectUris =>
                          "http://redirect.uri/",
                        oidcRPMetaDataOptionsPostLogoutRedirectUris =>
                          "http://auth.rp.com/oauth2/rlogoutreturn",
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

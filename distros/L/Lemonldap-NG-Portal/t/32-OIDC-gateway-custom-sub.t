# Non-regression test for #3627
#
# When LL::NG acts as an OIDC gateway (it authenticates users against an
# upstream OP through the Auth/OpenIDConnect module) *and* as an OIDC issuer
# for a downstream RP, the "sub" sent to the downstream RP must be computed
# from the RP's configured UserIDAttr.
#
# The #3560 fix stored a pre-computed "sub" in the "_oidc_sub" session key for
# online refresh tokens. But "_oidc_sub" is also set by the Auth/OpenIDConnect
# module with the "sub" returned by the upstream OP. As a result, the gateway
# wrongly returned the upstream "sub" to the downstream RP instead of the value
# of its configured UserIDAttr.
use warnings;
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
my ( $op, $gw, $res );

# The upstream OP and the gateway talk to each other through this fake UA
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.((?:o|g)p?w?).com(.*)#, ' REST request' );
        my $host = $1;
        my $url  = $2;
        my ( $r, $client );
        count(1);
        if ( $host eq 'op' ) {
            pass("  Request to OP, endpoint $url");
            $client = $op;
        }
        elsif ( $host eq 'gw' ) {
            pass("  Request to GW, endpoint $url");
            $client = $gw;
        }
        else {
            fail("  Aborting REST request (external) to $host");
            return [ 500, [], [] ];
        }
        if ( $req->method =~ /^post$/i ) {
            my $s = $req->content;
            ok(
                $r = $client->_post(
                    $url, IO::String->new($s),
                    length => length($s),
                    type   => $req->header('Content-Type'),
                ),
                '  Execute request'
            );
        }
        else {
            ok(
                $r = $client->_get(
                    $url,
                    custom => {
                        HTTP_AUTHORIZATION => $req->header('Authorization'),
                    }
                ),
                '  Execute request'
            );
        }
        ok( $r->[0] == 200, '  Response is 200' ) or explain( $r->[0], 200 );
        count(3);
        return $r;
    }
);

# Initialization: upstream OP
ok( $op = register( 'op', sub { op() } ), 'OP portal' );

ok( $res = $op->_get('/oauth2/jwks'), 'Get OP JWKS' );
expectOK($res);
my $jwks = $res->[2]->[0];

ok(
    $res = $op->_get('/.well-known/openid-configuration'),
    'Get OP metadata'
);
expectOK($res);
my $metadata = $res->[2]->[0];
count(3);

# Gateway: OIDC client of OP + OIDC issuer for the downstream "app"
&Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
ok( $gw = register( 'gw', sub { gw( $jwks, $metadata ) } ), 'GW portal' );
count(1);

# Authenticate the gateway against the upstream OP first, so it gets an SSO
# session whose data contains _oidc_sub set by the Auth/OpenIDConnect module
ok(
    $res = $gw->_get( '/', accept => 'text/html' ),
    'Unauthenticated request on gateway'
);
count(1);

# Gateway is not authenticated yet -> redirect to upstream OP
my ( $url, $query ) =
  expectRedirection( $res, qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

# Push request to OP
ok( $res = $op->_get( $url, query => $query, accept => 'text/html' ),
    "Push request to OP, endpoint $url" );
count(1);
expectOK($res);

# Authenticate "dwho" on the upstream OP
$query = "user=dwho&password=dwho&$query";
ok(
    $res = $op->_post(
        $url,
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
    ),
    "Authenticate dwho on OP"
);
count(1);
my $opId = expectCookie($res);
($query) =
  expectRedirection( $res, qr#^http://auth.gw.com/?\?(.*)$# );

# OP redirects back to the gateway's callback
ok(
    $res = $gw->_get( '/', query => $query, accept => 'text/html' ),
    'Call openidconnectcallback on gateway'
);
count(1);
my $gwId = expectCookie($res);

# Now the downstream "app" starts an authorization code flow on the gateway,
# reusing the gateway SSO session
$res = codeAuthorize(
    $gw, $gwId,
    {
        response_type => 'code',
        scope         => 'openid email',
        client_id     => 'appid',
        state         => 'af0ifjsldkj',
        redirect_uri  => 'http://app.com/callback',
    }
);
my $code = $res;
ok( $code, 'Got authorization code from gateway' );
count(1);

# The app exchanges the code against tokens on the gateway
$res =
  codeGrant( $gw, 'appid', $code, 'http://app.com/callback' );
my $json = expectJSON($res);
ok( $json->{id_token}, 'Gateway returned an id_token' );

my $payload = id_token_payload( $json->{id_token} );
count(1);

# The "sub" sent to the downstream app must come from its configured
# UserIDAttr (mail), NOT from the upstream OP "sub" stored in _oidc_sub.
is( $payload->{sub}, 'dwho@badwolf.org',
    'Downstream sub uses the app UserIDAttr (mail), not the upstream sub' );
count(1);

clean_sessions();
done_testing( count() );

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'op.com',
                portal                          => 'http://auth.op.com/',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => 1,
                oidcRPMetaDataExportedVars      => {
                    gw => {
                        email => "mail",
                        name  => "cn",
                    }
                },
                oidcServiceAllowAuthorizationCodeFlow => 1,
                oidcRPMetaDataOptions                 => {
                    gw => {
                        oidcRPMetaDataOptionsDisplayName   => "GW",
                        oidcRPMetaDataOptionsClientID      => "gwid",
                        oidcRPMetaDataOptionsClientSecret  => "gwsecret",
                        oidcRPMetaDataOptionsIDTokenSignAlg => "HS512",
                        oidcRPMetaDataOptionsBypassConsent => 1,
                        oidcRPMetaDataOptionsRedirectUris  =>
                          'http://auth.gw.com/?openidconnectcallback=1',
                    }
                },
                oidcServicePrivateKeySig => oidc_key_op_private_sig,
                oidcServicePublicKeySig  => oidc_cert_op_public_sig,
            }
        }
    );
}

sub gw {
    my ( $jwks, $metadata ) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel       => $debug,
                domain         => 'gw.com',
                portal         => 'http://auth.gw.com/',
                authentication => 'OpenIDConnect',
                userDB         => 'Same',

                # Gateway as OIDC client of the upstream OP
                oidcOPMetaDataExportedVars => {
                    op => {
                        cn   => "name",
                        mail => "email",
                    }
                },
                oidcOPMetaDataOptions => {
                    op => {
                        oidcOPMetaDataOptionsCheckJWTSignature => 1,
                        oidcOPMetaDataOptionsJWKSTimeout       => 0,
                        oidcOPMetaDataOptionsClientSecret      => "gwsecret",
                        oidcOPMetaDataOptionsScope     => "openid profile email",
                        oidcOPMetaDataOptionsStoreIDToken  => 0,
                        oidcOPMetaDataOptionsUserAttribute => "sub",
                        oidcOPMetaDataOptionsClientID         => "gwid",
                        oidcOPMetaDataOptionsConfigurationURI =>
                          "https://auth.op.com/.well-known/openid-configuration",
                    }
                },
                oidcOPMetaDataJWKS => { op => $jwks, },
                oidcOPMetaDataJSON => { op => $metadata, },

                # Gateway as OIDC issuer for the downstream app
                issuerDBOpenIDConnectActivation => 1,
                oidcRPMetaDataExportedVars      => {
                    app => {
                        email => "mail",
                    }
                },
                oidcServiceAllowAuthorizationCodeFlow => 1,
                oidcRPMetaDataOptions                 => {
                    app => {
                        oidcRPMetaDataOptionsDisplayName    => "App",
                        oidcRPMetaDataOptionsClientID       => "appid",
                        oidcRPMetaDataOptionsClientSecret   => "appid",
                        oidcRPMetaDataOptionsIDTokenSignAlg => "HS512",
                        oidcRPMetaDataOptionsBypassConsent  => 1,

                        # Custom UserIDAttr: the sub must be the user mail
                        oidcRPMetaDataOptionsUserIDAttr     => "mail",
                        oidcRPMetaDataOptionsRedirectUris   =>
                          'http://app.com/callback',
                    }
                },
                oidcServicePrivateKeySig => oidc_key_op_private_sig,
                oidcServicePublicKeySig  => oidc_cert_op_public_sig,
            }
        }
    );
}

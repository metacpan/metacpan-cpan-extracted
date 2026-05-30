use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use URI::QueryParam;

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
                    custom => {
                        HTTP_AUTHORIZATION => $req->header('Authorization'),
                    }
                ),
                '  Execute request'
            );
        }
        ok( $res->[0] == 200, '  Response is 200' );
        ok( getHeader( $res, 'Content-Type' ) =~ m#^application/json#,
            '  Content is JSON' )
          or explain( $res->[1], 'Content-Type => application/json' );
        return $res;
    }
);

# Initialization
ok( $op = register( 'op', sub { op() } ), 'OP portal' );

ok( $res = $op->_get('/oauth2/jwks'), 'Get JWKS' );
expectOK($res);
my $jwks = $res->[2]->[0];

ok( $res = $op->_get('/.well-known/openid-configuration'), 'Get metadata' );
expectOK($res);
my $metadata = $res->[2]->[0];

# RP with iss required
&Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
ok( $rp = register( 'rp', sub { rp( $jwks, $metadata ) } ),
    'RP portal with iss required' );

subtest 'Normal flow - OP sends iss, RP verifies (iss required)', sub {
    my ( $idpId, $url, $res )   = &_getCookie;
    my ( $host,  $tmp, $query ) = expectForm( $res, '#', undef, 'confirm' );

    ok(
        $res = $op->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
            length => length($query),
        ),
        "Post confirmation"
    );

    # Verify that iss parameter is in the response
    my ($callback_query) =
      expectRedirection( $res, qr#^http://auth.rp.com/?\?(.*)$# );
    my $callback_uri = URI->new("http://auth.rp.com/?$callback_query");
    ok( $callback_uri->query_param('iss'),
        "iss parameter present in callback (RFC 9207)" );
    is( $callback_uri->query_param('iss'),
        'http://auth.op.com/', "iss matches OP issuer" );

    # Push OP response to RP - should succeed
    ok(
        $res =
          $rp->_get( '/', query => $callback_query, accept => 'text/html' ),
        'Call openidconnectcallback on RP'
    );
    my $spId = expectCookie($res);
    ok( $spId, "RP session created with valid iss" );

    # Logout
    ok(
        $res = $rp->_get(
            '/',
            query  => 'logout',
            cookie => "lemonldap=$spId",
            accept => 'text/html'
        ),
        'Query RP for logout'
    );
};

subtest 'iss parameter mismatch', sub {
    my ( $idpId, $url, $res ) = &_getCookie;

    # Since consent was already given, we get a direct redirect
    my ($callback_query) =
      expectRedirection( $res, qr#^http://auth.rp.com/?\?(.*)$# );

    # Replace iss parameter with wrong value to simulate mix-up attack
    my $callback_uri = URI->new("http://auth.rp.com/?$callback_query");
    $callback_uri->query_param( 'iss', 'http://evil.attacker.com/' );
    my $modified_query = $callback_uri->query;

    ok(
        $res =
          $rp->_get( '/', query => $modified_query, accept => 'text/html' ),
        'Call openidconnectcallback on RP with wrong iss'
    );

    expectPortalError( $res, 106 );    # PE_OIDC_AUTH_ERROR
};

subtest 'iss required but missing', sub {
    my ( $idpId, $url, $res ) = &_getCookie;

    my ($callback_query) =
      expectRedirection( $res, qr#^http://auth.rp.com/?\?(.*)$# );

    # Remove iss parameter from callback to simulate an OP not sending it
    my $callback_uri = URI->new("http://auth.rp.com/?$callback_query");
    $callback_uri->query_param_delete('iss');
    my $modified_query = $callback_uri->query;

    ok(
        $res =
          $rp->_get( '/', query => $modified_query, accept => 'text/html' ),
        'Call openidconnectcallback on RP without iss'
    );

    expectPortalError( $res, 106 );    # PE_OIDC_AUTH_ERROR
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
                issuerDBOpenIDConnectActivation => "1",
                restSessionServer               => 1,
                restExportSecretKeys            => 1,
                oidcRPMetaDataExportedVars      => {
                    rp => {
                        email       => "mail",
                        family_name => "cn",
                        name        => "cn",
                    }
                },
                oidcServiceAllowAuthorizationCodeFlow => 1,
                oidcRPMetaDataOptions                 => {
                    rp => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 0,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsRedirectUris          =>
                          'http://auth.rp.com/?openidconnectcallback=1',
                    }
                },
                oidcOPMetaDataOptions    => {},
                oidcOPMetaDataJSON       => {},
                oidcOPMetaDataJWKS       => {},
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
                restExportSecretKeys       => 1,
                oidcOPMetaDataExportedVars => {
                    op => {
                        cn   => "name",
                        uid  => "sub",
                        sn   => "family_name",
                        mail => "email",
                    }
                },
                oidcOPMetaDataOptions => {
                    op => {
                        oidcOPMetaDataOptionsCheckJWTSignature => 1,
                        oidcOPMetaDataOptionsJWKSTimeout       => 0,
                        oidcOPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcOPMetaDataOptionsScope    => "openid profile email",
                        oidcOPMetaDataOptionsClientID => "rpid",
                        oidcOPMetaDataOptionsUseNonce => 1,
                        oidcOPMetaDataOptionsRequireIss       => 1,
                        oidcOPMetaDataOptionsConfigurationURI =>
                          "https://auth.op.com/.well-known/openid-configuration"
                    }
                },
                oidcOPMetaDataJWKS => {
                    op => $jwks,
                },
                oidcOPMetaDataJSON => {
                    op => $metadata,
                },
            }
        }
    );
}

sub _getCookie {

    # Query RP for auth
    ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth RP request' );
    my ( $url, $query ) =
      expectRedirection( $res,
        qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

    # Push request to OP
    ok( $res = $op->_get( $url, query => $query, accept => 'text/html' ),
        "Push request to OP" );
    expectOK($res);

    # Authenticate to OP
    $query = "user=french&password=french&$query";
    ok(
        $res = $op->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
        ),
        "Post authentication"
    );
    return ( expectCookie($res), $url, $res );
}

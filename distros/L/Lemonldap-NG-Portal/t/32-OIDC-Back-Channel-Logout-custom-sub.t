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
my ( $op, $rp, $res );

# Store captured values for verification
my ( $id_token_sub, $logout_token_sub, $refresh_token );

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

            # Capture the logout_token for verification
            if ( $url =~ /blogout/ ) {
                my $content = $req->content;
                if ( $content =~ /logout_token=([^&]+)/ ) {
                    my $jwt = $1;
                    $jwt =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
                    my $payload = getJWTPayload($jwt);
                    $logout_token_sub = $payload->{sub};
                    pass("  Captured logout_token sub: $logout_token_sub");
                }
            }
        }
        else {
            fail('  Aborting REST request (external)');
            return [ 500, [], [] ];
        }
        if ( $req->method =~ /^post$/i ) {
            my $s = $req->content || '';
            ok(
                $res = $client->_post(
                    $url,
                    IO::String->new($s),
                    length => length($s),
                    type   => $req->header('Content-Type'),
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
        else {
            ok(
                $res = $client->_get(
                    $url,
                    custom => {
                        HTTP_AUTHORIZATION => $req->header('Authorization')
                          || '',
                    }
                ),
                '  Execute request'
            );
        }
        ok( $res->[0] == 200, '  Response is 200' )
          or explain( $res, "Expected 200" );
        if ( $url !~ /(?:blogout|revoke)/ ) {
            ok( getHeader( $res, 'Content-Type' ) =~ m#^application/json#,
                '  Content is JSON' )
              or explain( $res->[1], 'Content-Type => application/json' );

            # Capture id_token and refresh_token from token endpoint response
            if ( $res->[2]->[0] =~ /"id_token"\s*:\s*"([^"]+)"/ ) {
                my $id_token = $1;
                my $payload  = getJWTPayload($id_token);
                $id_token_sub = $payload->{sub};
                pass("  Captured id_token sub: $id_token_sub");
            }
            if ( $res->[2]->[0] =~ /"refresh_token"\s*:\s*"([^"]+)"/ ) {
                $refresh_token = $1;
                pass("  Captured refresh_token: $refresh_token");
            }
        }
        return $res;
    }
);

# Initialization
ok( $op = register( 'op', sub { op() } ), 'OP portal' );

ok( $res = $op->_get('/oauth2/jwks'), 'Get JWKS,     endpoint /oauth2/jwks' );
expectOK($res);
my $jwks = $res->[2]->[0];

ok(
    $res = $op->_get('/.well-known/openid-configuration'),
    'Get metadata, endpoint /.well-known/openid-configuration'
);
expectOK($res);
my $metadata = $res->[2]->[0];

&Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
ok( $rp = register( 'rp', sub { rp( $jwks, $metadata ) } ), 'RP portal' );

subtest "Back-Channel Logout from OP with custom sub" => sub {

    ( $id_token_sub, $logout_token_sub, $refresh_token ) =
      ( undef, undef, undef );

    # Query RP for auth
    ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth RP request' );
    my ( $url, $query ) =
      expectRedirection( $res,
        qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

    # Push request to OP
    ok( $res = $op->_get( $url, query => $query, accept => 'text/html' ),
        "Push request to OP,         endpoint $url" );
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
    my $idpId = expectCookie($res);

    ($query) = expectRedirection( $res, qr#^http://auth.rp.com/?\?(.*)$# );

    # Push OP response to RP
    ok( $res = $rp->_get( '/', query => $query, accept => 'text/html' ),
        'Call openidconnectcallback on RP' );
    my $spId = expectCookie($res);

    # Verify the sub in id_token is the custom one (mail attribute)
    ok( $id_token_sub, 'ID token sub was captured' );
    is( $id_token_sub, 'fa@badwolf.org',
        'ID token sub uses custom UserIDAttr (mail)' );

    # Logout initiated by OP - this should trigger back-channel logout
    ok(
        $res = $op->_get(
            '/',
            query  => 'logout',
            cookie => "lemonldap=$idpId",
            accept => 'text/html'
        ),
        'Query OP for logout'
    );
    expectOK($res);

    # Verify the sub in logout_token matches the one in id_token
    ok( $logout_token_sub, 'Logout token sub was captured' );
    is( $logout_token_sub, 'fa@badwolf.org',
        'Logout token sub uses custom UserIDAttr (mail)' );
    is( $logout_token_sub, $id_token_sub,
        'Logout token sub matches ID token sub' );

    # Test if logout is done
    ok(
        $res = $op->_get(
            '/', cookie => "lemonldap=$idpId",
        ),
        'Test if user is reject on OP'
    );
    expectReject($res);

    ok(
        $res = $rp->_get(
            '/',
            cookie => "lemonldap=$spId",
            accept => 'text/html'
        ),
        'Test if user is reject on RP'
    );
    expectRedirection( $res, qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );
};

subtest "Back-Channel Logout via token revocation with custom sub" => sub {

    ( $id_token_sub, $logout_token_sub, $refresh_token ) =
      ( undef, undef, undef );

    # Query RP for auth
    ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth RP request' );
    my ( $url, $query ) =
      expectRedirection( $res,
        qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

    # Push request to OP
    ok( $res = $op->_get( $url, query => $query, accept => 'text/html' ),
        "Push request to OP,         endpoint $url" );
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
    my $idpId = expectCookie($res);

    # With BypassConsent, we get redirected directly
    ($query) = expectRedirection( $res, qr#^http://auth.rp.com/?\?(.*)$# );

    # Push OP response to RP
    ok( $res = $rp->_get( '/', query => $query, accept => 'text/html' ),
        'Call openidconnectcallback on RP' );
    my $spId = expectCookie($res);

    # Verify the sub in id_token is the custom one (mail attribute)
    ok( $id_token_sub, 'ID token sub was captured' );
    is( $id_token_sub, 'fa@badwolf.org',
        'ID token sub uses custom UserIDAttr (mail)' );

    # Verify we got a refresh token
    ok( $refresh_token, 'Refresh token was captured' );

    # Reset logout_token_sub before revocation
    $logout_token_sub = undef;

    # Revoke the refresh token - this should trigger back-channel logout
    $query = "token=$refresh_token&token_type_hint=refresh_token";
    ok(
        $res = $op->_post(
            '/oauth2/revoke',
            IO::String->new($query),
            length => length($query),
            custom => {
                HTTP_AUTHORIZATION => "Basic "
                  . encode_base64( "rpid:rpsecret", '' )
            }
        ),
        'Revoke refresh token'
    );
    expectOK($res);

    # Verify the sub in logout_token matches the one in id_token
    ok( $logout_token_sub, 'Logout token sub was captured after revocation' );
    is( $logout_token_sub, 'fa@badwolf.org',
        'Logout token sub uses custom UserIDAttr (mail) after revocation' );
    is( $logout_token_sub, $id_token_sub,
        'Logout token sub matches ID token sub after revocation' );

    # Cleanup: logout from OP
    ok(
        $res = $op->_get(
            '/',
            query  => 'logout',
            cookie => "lemonldap=$idpId",
            accept => 'text/html'
        ),
        'Cleanup: Query OP for logout'
    );
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
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 1,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",

                        # Custom UserIDAttr - use mail instead of uid
                        oidcRPMetaDataOptionsUserIDAttr => "mail",

                        # Enable refresh tokens (online, not offline)
                        oidcRPMetaDataOptionsRefreshToken => 1,

                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsLogoutUrl             =>
                          'http://auth.rp.com/oauth2/blogout',
                        oidcRPMetaDataOptionsLogoutType            => 'back',
                        oidcRPMetaDataOptionsLogoutSessionRequired => 1,
                        oidcRPMetaDataOptionsRedirectUris          =>
                          'http://auth.rp.com/?openidconnectcallback=1',
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
                          "https://auth.op.com/.well-known/openid-configuration"
                    }
                },
                oidcOPMetaDataJWKS => {
                    op => $jwks,
                },
                oidcOPMetaDataJSON => {
                    op => $metadata,
                }
            }
        }
    );
}

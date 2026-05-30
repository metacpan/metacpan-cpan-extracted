use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use URI;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my ( $op, $rp, $res );

# Track token request to verify hook parameter
my $token_request_content = '';

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

            # Capture token request content for verification
            if ( $url =~ /token/ ) {
                $token_request_content = $s;
            }
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

&Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );

# Reset all hook markers before creating RP
$t::OidcClientHookPlugin::authzCallbackHookCalled = '';
$t::OidcClientHookPlugin::authRequestHookCalled   = '';
$t::OidcClientHookPlugin::tokenRequestHookCalled  = '';
$t::OidcClientHookPlugin::gotIDTokenHookCalled    = '';
$t::OidcClientHookPlugin::gotUserInfoHookCalled   = '';
$t::OidcClientHookPlugin::idTokenHookData         = '';
$t::OidcClientHookPlugin::userInfoHookData        = '';

ok( $rp = register( 'rp', sub { rp( $jwks, $metadata ) } ), 'RP portal' );

# Query RP for auth - this triggers oidcGenerateAuthenticationRequest hook
ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth SP request' );
my ($uri) =
  expectRedirection( $res, qr#(http://auth.op.com/oauth2/authorize\?.*)$# );

$uri = URI->new($uri);
my $url   = $uri->path;
my $query = $uri->query;

# --------------------------------------------------------------------------
# Test oidcGenerateAuthenticationRequest hook
# --------------------------------------------------------------------------
ok(
    $t::OidcClientHookPlugin::authRequestHookCalled,
    'oidcGenerateAuthenticationRequest hook was called'
);

my $params = $uri->query_form_hash;

# Verify custom parameter was added to the auth request
is( $params->{custom_auth_param}, "auth_hook_value",
'oidcGenerateAuthenticationRequest hook added custom parameter to auth request'
);
is( $params->{badjson}, '{xx/h',
    "Value that looks like json but isn't json is passed as-is" );
my $decoded_claims = from_json( $params->{claims} );
is_deeply(
    $decoded_claims,
    {
        'id_token' => {
            'amr' => {
                'essential' => JSON::true,
            },
            'my_claim' => undef
        }
    },
    "Claims parameter was correctly edited by the hook"
);

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
    "Post confirmation"
);

($query) = expectRedirection( $res, qr#^http://auth.rp.com/?\?(.*)$# );

# Push OP response to RP - this triggers oidcGotAuthenticationResponse hook
# and then oidcGenerateTokenRequest, oidcGotIDToken, oidcGotUserInfo hooks
ok( $res = $rp->_get( '/', query => $query, accept => 'text/html' ),
    'Call openidconnectcallback on RP' );
my $spId = expectCookie($res);

# --------------------------------------------------------------------------
# Test oidcGotAuthenticationResponse hook
# --------------------------------------------------------------------------
ok(
    $t::OidcClientHookPlugin::authzCallbackHookCalled,
    'oidcGotAuthenticationResponse hook was called'
);

# --------------------------------------------------------------------------
# Test oidcGenerateTokenRequest hook
# --------------------------------------------------------------------------
ok(
    $t::OidcClientHookPlugin::tokenRequestHookCalled,
    'oidcGenerateTokenRequest hook was called'
);

# Verify custom parameter was added to the token request
like(
    $token_request_content,
    qr/custom_token_param=token_hook_value/,
    'oidcGenerateTokenRequest hook added custom parameter to token request'
);

# --------------------------------------------------------------------------
# Test oidcGotIDToken hook
# --------------------------------------------------------------------------
ok( $t::OidcClientHookPlugin::gotIDTokenHookCalled,
    'oidcGotIDToken hook was called' );

is( $t::OidcClientHookPlugin::idTokenHookData,
    'op/french', 'oidcGotIDToken hook received correct OP name and sub' );

# --------------------------------------------------------------------------
# Test oidcGotUserInfo hook
# --------------------------------------------------------------------------
ok( $t::OidcClientHookPlugin::gotUserInfoHookCalled,
    'oidcGotUserInfo hook was called' );

is( $t::OidcClientHookPlugin::userInfoHookData,
    'op/french', 'oidcGotUserInfo hook received correct OP name and sub' );

clean_sessions();
done_testing();

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                domain                          => 'idp.com',
                portal                          => 'http://auth.op.com/',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => "1",
                restSessionServer               => 1,
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
                        oidcRPMetaDataOptionsUserIDAttr        => "",
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
                        mail => "email",
                    }
                },
                oidcOPMetaDataOptions => {
                    op => {
                        oidcOPMetaDataOptionsCheckJWTSignature => 1,
                        oidcOPMetaDataOptionsJWKSTimeout       => 0,
                        oidcOPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcOPMetaDataOptionsScope    => "openid profile email",
                        oidcOPMetaDataOptionsDisplay  => "",
                        oidcOPMetaDataOptionsClientID => "rpid",
                        oidcOPMetaDataOptionsUseNonce => 1,
                        oidcOPMetaDataOptionsConfigurationURI =>
"https://auth.op.com/.well-known/openid-configuration",
                        oidcOPMetaDataOptionsAuthEndpointExtraParams => {
                            myparam => '42',
                            badjson => '{xx/',
                            claims  =>
'{ "id_token": { "amr": { "essential": true } } }',
                        },
                    }
                },
                oidcOPMetaDataJWKS => {
                    op => $jwks,
                },
                oidcOPMetaDataJSON => {
                    op => $metadata,
                },
                customPlugins => 't::OidcClientHookPlugin',
            }
        }
    );
}

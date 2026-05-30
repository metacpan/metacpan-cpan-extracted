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
            oidcRPMetaDataOptions => {
                rp => {
                    oidcRPMetaDataOptionsDisplayName           => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rpid",
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsAccessTokenJWT        => 1,
                    oidcRPMetaDataOptionsClientSecret          => "rpid",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRefreshToken          => 1,
                    oidcRPMetaDataOptionsAllowOffline          => 1,
                    oidcRPMetaDataOptionsRedirectUris => 'http://rp2.com/',
                },
                'dev-rp' => {
                    oidcRPMetaDataOptionsClientID      => "dev-rp",
                    oidcRPMetaDataOptionsClientSecret  => "rpid",
                    oidcRPMetaDataOptionsBypassConsent => 1,
                    oidcRPMetaDataOptionsRedirectUris  => 'http://dev.com/',
                },
                oauth => {
                    oidcRPMetaDataOptionsDisplayName  => "oauth",
                    oidcRPMetaDataOptionsClientID     => "oauth",
                    oidcRPMetaDataOptionsClientSecret => "service",
                    oidcRPMetaDataOptionsUserIDAttr   => "",
                    oidcRPMetaDataOptionsAllowClientCredentialsGrant => 1,
                }
            },
            oidcServicePrivateKeySig            => oidc_key_op_private_sig,
            oidcServicePublicKeySig             => oidc_cert_op_public_sig,
            oidcServiceAllowDynamicRegistration => 1,
            customPlugins                       => 't::OidcHookPlugin',
        }
    }
);
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

# Test Redirect URI validation
ok(
    $res = $op->_get(
        "/oauth2/authorize",
        query => {
            response_type => "code",
            scope         => "openid",
            client_id     => "dev-rp",
            redirect_uri  => "http://dev.com/",
        },
        accept => 'text/html',
        cookie => "lemonldap=$idpId",
    ),
    "Authorized URL is denied by hook during login"
);
expectPortalError( $res, 108, "Declared URL was denied by hook" );

ok(
    $res = $op->_get(
        "/oauth2/logout",
        query => {
            client_id                => "dev-rp",
            post_logout_redirect_uri => "http://dev.com/",
        },
        accept => 'text/html',
        cookie => "lemonldap=$idpId",
    ),
    "Authorized URL is denied by hook during logout"
);
expectPortalError( $res, 108, "Declared URL was denied by hook" );

ok(
    $res = $op->_get(
        "/oauth2/logout",
        query => {
            client_id                => "dev-rp",
            post_logout_redirect_uri => "http://dev.com/",
        },
        accept => 'text/html',
    ),
    "Authorized URL is denied by hook during unauth logout"
);
expectPortalError( $res, 9, "Declared URL was denied by hook" );

ok(
    $res = $op->_get(
        "/oauth2/authorize",
        query => {
            response_type => "code",
            scope         => "openid",
            client_id     => "dev-rp",
            redirect_uri  => "http://localhost:123/456",
        },
        accept => 'text/html',
        cookie => "lemonldap=$idpId",
    ),
    "Unauthorized URL is allowed by hook during login"
);
expectRedirection( $res, qr#http://localhost:123/456\?.*code=([^\&]*)# );

# Get code for RP1
$query =
"response_type=code&scope=openid%20profile%20email&client_id=rpid&state=af0ifjsldkj&redirect_uri=http%3A%2F%2Frp2.com%2F";
ok(
    $res = $op->_get(
        "/oauth2/authorize",
        query  => "$query",
        accept => 'text/html',
        cookie => "lemonldap=$idpId",
    ),
    "Get authorization code"
);

# Check that both oidcGenerateCode (hooked=1) and oidcGenerateAuthorizationResponse (authz_hook=hooked) hooks work
my ($redir_url) = expectRedirection( $res, qr#(http://rp2\.com/\?.*)# );
like( $redir_url, qr/\bhooked=1\b/,
    "oidcGenerateCode hook modified redirect_uri" );
like( $redir_url, qr/\bauthz_hook=hooked\b/,
    "oidcGenerateAuthorizationResponse hook added parameter" );
my ($code) = ( $redir_url =~ /\bcode=([^\&]+)/ );

# Exchange code for AT
$query =
"grant_type=authorization_code&code=$code&redirect_uri=http%3A%2F%2Frp2.com%2F";

ok(
    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid:rpid"),
        },
    ),
    "Post token"
);
my $json  = from_json( $res->[2]->[0] );
my $token = $json->{access_token};
ok( $token, 'Access token present' );
my $id_token = $json->{id_token};
ok( $id_token, 'ID token present' );
my $refresh_token = $json->{refresh_token};
ok( $refresh_token, 'Refresh token present' );
my $customToken = $json->{custom_token};
is( $customToken, 'CustomToken', 'Found custom token in token response' );
is( $t::OidcHookPlugin::lastTokenResponseGrantType,
    'authorization_code',
    'oidcGenerateTokenResponse received grant_type=authorization_code' );
my $id_token_payload = id_token_payload($id_token);
is( $id_token_payload->{id_token_hook}, 1, "Found hooked claim in ID token" );
is( $id_token_payload->{id_token_hook_uid},
    "french", "Found hooked claim in ID token" );
is( $id_token_payload->{id_token_hook_rp},
    "rp", "Found hooked claim in ID token" );

# 3084
my $id_token_header = id_token_header($id_token);
ok( !exists $id_token_header->{kid}, "HS** ID token has no kid header" );
is( $id_token_header->{id_token_hook_header}, 1, "Found hooked JWT header" );

# Reset conf to make sure lazy loading works
$op->p->HANDLER->checkConf(1);

# Get userinfo
$res = $op->_post(
    "/oauth2/userinfo",
    IO::String->new(''),
    accept => 'application/json',
    length => 0,
    custom => {
        HTTP_AUTHORIZATION => "Bearer " . $token,
    },
);

$json = expectJSON($res);
is( $json->{userinfo_hook}, 1, "Found hooked claim in Userinfo token" );
is( $json->{_auth}, "Demo",    "Found injected variable in Userinfo token" );
is( $json->{email}, 'fa@badwolf.org',
    "Found exported attribute variable in Userinfo token" );
like( $json->{_scope}, qr/\bopenid\b/, "Scopes are visible in hook" );

expectJWT( $token, access_token_hook => 1 );

is( getJWTHeader($token)->{typ}, "at+JWT+hook", "hooked access token type" );

# Reset conf to make sure lazy loading works
$op->p->HANDLER->checkConf(1);

# Introspect to find scopes
$query = "token=$token";
ok(
    $res = $op->_post(
        "/oauth2/introspect",
        IO::String->new($query),
        accept => 'text/html',
        length => length $query,
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("oauth:service"),
        },
    ),
    "Post introspection"
);

expectOK($res);
$json = from_json( $res->[2]->[0] );
like( $json->{scope}, qr/\bmy_hooked_scope\b/, "Found hook defined scope" );
like( $json->{scope}, qr/\bmyscope\b/, "Found result of oidcResolveScope" );

# Reset conf to make sure lazy loading works
$op->p->HANDLER->checkConf(1);

# Refresh access token
$res  = refreshGrant( $op, 'rpid', $refresh_token );
$json = expectJSON($res);

$token = $json->{access_token};
ok( $token, 'Access token present' );

# Make sure the Refresh hook added a scope to the token
expectJWT( $token,
    scope =>
      "openid profile email my_hooked_scope myscope refreshed_online_french" );

## Test Offline refresh hook
$code = codeAuthorize(
    $op, $idpId,
    {
        response_type => 'code',
        scope         => 'openid profile email offline_access',
        client_id     => 'rpid',
        state         => 'af0ifjsldkj',
        redirect_uri  => 'http://rp2.com/',
    }
);

$json = expectJSON( codeGrant( $op, 'rpid', $code, "http://rp2.com/" ) );
$refresh_token = $json->{refresh_token};
ok( $refresh_token, 'Refresh token present' );

# Reset conf to make sure lazy loading works
$op->p->HANDLER->checkConf(1);

$json = expectJSON( refreshGrant( $op, 'rpid', $refresh_token ) );
expectJWT( $json->{access_token},
    scope => "openid profile email my_hooked_scope myscope refreshed_french" );

# --------------------------------------------------------------------------
# Test oidcGenerateIntrospectionResponse hook
# --------------------------------------------------------------------------
note "Testing oidcGenerateIntrospectionResponse hook";

# Get a token via client credentials to introspect
$query = "grant_type=client_credentials&scope=openid";
ok(
    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'application/json',
        length => length($query),
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("oauth:service"),
        },
    ),
    "Get client credentials token"
);
$json = expectJSON($res);
my $cc_token = $json->{access_token};
ok( $cc_token, "Got access token" );

# Introspect to verify hook
$query = "token=$cc_token";
ok(
    $res = $op->_post(
        "/oauth2/introspect",
        IO::String->new($query),
        accept => 'application/json',
        length => length $query,
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("oauth:service"),
        },
    ),
    "Introspect token"
);

$json = expectJSON($res);
is( $json->{introspection_hook},
    "hooked", "oidcGenerateIntrospectionResponse hook modified response" );

# --------------------------------------------------------------------------
# Test oidcGotTokenRequest hook
# --------------------------------------------------------------------------
note "Testing oidcGotTokenRequest hook";

$query = "grant_type=urn:test:custom_grant";
ok(
    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'application/json',
        length => length($query),
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("oauth:service"),
        },
    ),
    "Custom grant type via oidcGotTokenRequest hook"
);
$json = expectJSON($res);
is( $json->{custom_grant}, 1,
    "oidcGotTokenRequest hook handled custom grant type" );
is( $json->{grant_type}, "urn:test:custom_grant",
    "Correct grant_type in hook response" );

# --------------------------------------------------------------------------
# Test oidcGenerateRefreshToken hook
# --------------------------------------------------------------------------
note "Testing oidcGenerateRefreshToken hook";

# Reset hook marker
$t::OidcHookPlugin::generateRefreshTokenCalled = '';

# Get a new refresh token
$code = codeAuthorize(
    $op, $idpId,
    {
        response_type => 'code',
        scope         => 'openid profile offline_access',
        client_id     => 'rpid',
        state         => 'teststate3',
        redirect_uri  => 'http://rp2.com/',
    }
);
$json = expectJSON( codeGrant( $op, 'rpid', $code, "http://rp2.com/" ) );
ok( $json->{refresh_token}, "Refresh token present" );
ok(
    $t::OidcHookPlugin::generateRefreshTokenCalled,
    "oidcGenerateRefreshToken hook was called"
);

# --------------------------------------------------------------------------
# Test oidcGenerateTokenResponse grant_type in refresh grant
# --------------------------------------------------------------------------
note "Testing oidcGenerateTokenResponse grant_type parameter in refresh grant";

$code = codeAuthorize(
    $op, $idpId,
    {
        response_type => 'code',
        scope         => 'openid profile email',
        client_id     => 'rpid',
        state         => 'teststate4',
        redirect_uri  => 'http://rp2.com/',
    }
);

$json = expectJSON( codeGrant( $op, 'rpid', $code, "http://rp2.com/" ) );
$refresh_token = $json->{refresh_token};
ok( $refresh_token, 'Refresh token present' );

$t::OidcHookPlugin::lastTokenResponseGrantType = '';
$json = expectJSON( refreshGrant( $op, 'rpid', $refresh_token ) );
is( $t::OidcHookPlugin::lastTokenResponseGrantType,
    'refresh_token',
    'oidcGenerateTokenResponse received grant_type=refresh_token' );
is( $json->{custom_token}, 'CustomToken',
    'oidcGenerateTokenResponse hook modified refresh response' );

# --------------------------------------------------------------------------
# Test PE_SENDRESPONSE in oidcGotOnlineRefresh
# --------------------------------------------------------------------------
note "Testing PE_SENDRESPONSE in oidcGotOnlineRefresh";

$code = codeAuthorize(
    $op, $idpId,
    {
        response_type => 'code',
        scope         => 'openid profile email',
        client_id     => 'rpid',
        state         => 'teststate5',
        redirect_uri  => 'http://rp2.com/',
    }
);

$json = expectJSON( codeGrant( $op, 'rpid', $code, "http://rp2.com/" ) );
$refresh_token = $json->{refresh_token};
ok( $refresh_token, 'Refresh token present for PE_SENDRESPONSE test' );

# Enable PE_SENDRESPONSE in hook
$t::OidcHookPlugin::refreshSendResponse = 1;

$res = refreshGrant( $op, 'rpid', $refresh_token );
is(
    $res->[2]->[0],
    'Direct response',
    'Online refresh: PE_SENDRESPONSE returns hook response body'
);

# Disable and verify normal refresh still works
$t::OidcHookPlugin::refreshSendResponse = 0;

$res  = refreshGrant( $op, 'rpid', $refresh_token );
$json = expectJSON($res);
ok( $json->{access_token},
    'Online refresh: normal refresh works after PE_SENDRESPONSE' );

# --------------------------------------------------------------------------
# Test PE_SENDRESPONSE in oidcGotOfflineRefresh
# --------------------------------------------------------------------------
note "Testing PE_SENDRESPONSE in oidcGotOfflineRefresh";

$code = codeAuthorize(
    $op, $idpId,
    {
        response_type => 'code',
        scope         => 'openid profile email offline_access',
        client_id     => 'rpid',
        state         => 'teststate6',
        redirect_uri  => 'http://rp2.com/',
    }
);

$json = expectJSON( codeGrant( $op, 'rpid', $code, "http://rp2.com/" ) );
$refresh_token = $json->{refresh_token};
ok( $refresh_token, 'Offline refresh token present for PE_SENDRESPONSE test' );

# Enable PE_SENDRESPONSE in hook
$t::OidcHookPlugin::refreshSendResponse = 1;

$res = refreshGrant( $op, 'rpid', $refresh_token );
is(
    $res->[2]->[0],
    'Direct response',
    'Offline refresh: PE_SENDRESPONSE returns hook response body'
);

# Disable and verify normal refresh still works
$t::OidcHookPlugin::refreshSendResponse = 0;

$res  = refreshGrant( $op, 'rpid', $refresh_token );
$json = expectJSON($res);
ok( $json->{access_token},
    'Offline refresh: normal refresh works after PE_SENDRESPONSE' );

# Testing oidcGenerateMetadata hook
note "Testing oidcGenerateMetadata hook";
ok(
    $res = $op->_get(
        '/.well-known/openid-configuration',
        accept => 'application/json',
    ),
    'Get metadata'
);
count(1);
expectOK($res);
count(1);
$json = expectJSON($res);
count(1);
ok(
    $json->{custom_metadata_hook} eq 'hooked',
    'oidcGenerateMetadata hook added custom field'
);
count(1);
ok(
    grep( { $_ eq 'urn:test:custom_grant' }
        @{ $json->{grant_types_supported} } ),
    'oidcGenerateMetadata hook added custom grant type'
);
count(1);

# --------------------------------------------------------------------------
# Test oidcGotRegistrationRequest and oidcRegisterClient hooks
# --------------------------------------------------------------------------
note "Testing oidcGotRegistrationRequest and oidcRegisterClient hooks";

# Test that registration is denied by hook for matching denied pattern
my $reg_metadata = to_json( {
        redirect_uris => ["https://denied.example.com/callback"],
        client_name   => "Test Client"
    }
);
ok(
    $res = $op->_post(
        "/oauth2/register",
        IO::String->new($reg_metadata),
        accept => 'application/json',
        length => length($reg_metadata),
        type   => 'application/json',
    ),
    "Registration attempt with denied redirect_uri"
);

is( $res->[0], 403, "Registration denied by hook returns 403" );

# Test that registration succeeds for allowed redirect_uri
$reg_metadata = to_json( {
        redirect_uris => ["https://allowed.example.com/callback"],
        client_name   => "Test Allowed Client"
    }
);
ok(
    $res = $op->_post(
        "/oauth2/register",
        IO::String->new($reg_metadata),
        accept => 'application/json',
        length => length($reg_metadata),
        type   => 'application/json',
    ),
    "Registration attempt with allowed redirect_uri"
);

# RFC 7591: Successful registration returns 201 Created
is( $res->[0], 201, "Registration returns 201 Created" );
$json = from_json( $res->[2]->[0] );
ok( $json->{client_id}, "Registration succeeded with client_id" );

# Verify that the oidcRegisterClient hook modified the saved RP options
my $savedConf = from_json(
    do { local ( @ARGV, $/ ) = "$main::tmpDir/lmConf-2.json"; <> }
);
my ($newRpKey) =
  grep {
    ( $savedConf->{oidcRPMetaDataOptions}->{$_}
          ->{oidcRPMetaDataOptionsClientID} || '' ) eq $json->{client_id}
  } keys %{ $savedConf->{oidcRPMetaDataOptions} };
ok( $newRpKey, "Newly registered RP found in saved configuration" );
is(
    $savedConf->{oidcRPMetaDataOptions}->{$newRpKey}
      ->{oidcRPMetaDataOptionsBypassConsent},
    1,
    "oidcRegisterClient hook set BypassConsent on the new RP"
);

clean_sessions();
done_testing();


use warnings;
use Test::More;
use strict;
use IO::String;
use MIME::Base64;
use JSON;
use Crypt::JWT qw(encode_jwt);

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

# Public clients are not authenticated: they must not be allowed to use the
# introspection endpoint (RFC 7662 section 2.1), whatever they send

my $debug = 'error';

my $op = LLNG::Manager::Test->new( {
        ini => {
            logLevel                        => $debug,
            domain                          => 'op.com',
            portal                          => 'http://auth.op.com/',
            authentication                  => 'Demo',
            userDB                          => 'Same',
            issuerDBOpenIDConnectActivation => 1,
            oidcRPMetaDataExportedVars      => {
                rp        => { email => "mail" },
                oauth     => { email => "mail" },
                spa       => { email => "mail" },
                pubsecret => { email => "mail" },
            },
            oidcRPMetaDataOptions => {
                rp => {
                    oidcRPMetaDataOptionsDisplayName           => "RP",
                    oidcRPMetaDataOptionsClientID              => "rpid",
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rpid",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRedirectUris => 'http://rp2.com/',
                },

                # Confidential resource server
                oauth => {
                    oidcRPMetaDataOptionsDisplayName  => "oauth",
                    oidcRPMetaDataOptionsClientID     => "oauth",
                    oidcRPMetaDataOptionsClientSecret => "service",
                    oidcRPMetaDataOptionsUserIDAttr   => "",
                },

                # Public client with its own user identifier
                spa => {
                    oidcRPMetaDataOptionsDisplayName  => "SPA",
                    oidcRPMetaDataOptionsClientID     => "spa",
                    oidcRPMetaDataOptionsPublic       => 1,
                    oidcRPMetaDataOptionsUserIDAttr   => "mail",
                    oidcRPMetaDataOptionsRedirectUris => 'http://spa.com/',
                },

                # Public client with a registered secret: it may authenticate
                pubsecret => {
                    oidcRPMetaDataOptionsDisplayName  => "Public with secret",
                    oidcRPMetaDataOptionsClientID     => "pubsecret",
                    oidcRPMetaDataOptionsClientSecret => "pubsecret",
                    oidcRPMetaDataOptionsPublic       => 1,
                    oidcRPMetaDataOptionsUserIDAttr   => "",
                    oidcRPMetaDataOptionsRedirectUris => "http://pub.com/",
                },
            },
            oidcServicePrivateKeySig => oidc_key_op_private_sig,
            oidcServicePublicKeySig  => oidc_cert_op_public_sig,
        }
    }
);

my $idpId = login( $op, "french" );
my $code  = codeAuthorize(
    $op, $idpId,
    {
        response_type => "code",
        scope         => "openid profile email",
        client_id     => "rpid",
        state         => "af0ifjsldkj",
        redirect_uri  => "http://rp2.com/"
    }
);
my $token =
  expectJSON( codeGrant( $op, "rpid", $code, "http://rp2.com/" ) )
  ->{access_token};
ok( $token, 'Access token issued to a confidential RP' );

sub callIntrospection {
    my ( $body, $authorization ) = @_;
    return $op->_post(
        "/oauth2/introspect",
        IO::String->new($body),
        accept => 'application/json',
        length => length($body),
        (
            $authorization
            ? ( custom => { HTTP_AUTHORIZATION => $authorization } )
            : ()
        ),
    );
}

# client_secret_jwt assertion signed with $key
sub jwsAuth {
    my ( $clientId, $key ) = @_;
    my $jwt = encode_jwt(
        payload => {
            iss => $clientId,
            sub => $clientId,
            aud => "http://auth.op.com/oauth2/introspect",
            exp => time + 100,
        },
        alg => "HS256",
        key => $key,
    );
    return
        "&client_id=$clientId"
      . "&client_assertion_type=urn%3Aietf%3Aparams%3Aoauth%3Aclient-assertion-type%3Ajwt-bearer"
      . "&client_assertion=$jwt";
}

# A wrong client secret or JWS gives invalid_client (400, or 401 with an
# Authorization header), a missing client authentication unauthorized_client
sub expectRefused {
    my ( $res, $msg, $code, $error ) = @_;
    is( $res->[0], $code, "$msg: HTTP code is $code" );
    is( eval { from_json( $res->[2]->[0] )->{error} },
        $error, "$msg: error is $error" );
    unlike( $res->[2]->[0], qr/"active"/, "$msg: no introspection response" )
      or diag( $res->[2]->[0] );
}

# Non regression: an authenticated confidential client gets the response
my $res =
  callIntrospection( "token=$token",
    "Basic " . encode_base64( "oauth:service", '' ) );
my $json = expectJSON($res);
ok( $json->{active}, 'Confidential client: token is active' );
is( $json->{sub}, 'french', 'Confidential client: sub of the calling RP' );

# Non regression (#3156): a confidential client may use a JWS
$json = expectJSON(
    callIntrospection( "token=$token" . jwsAuth( "oauth", "service" ) ) );
ok( $json->{active},
    "Confidential client, client_secret_jwt: token is active" );

# Public client without secret: a given secret is ignored, the client is not
# authenticated
$res =
  callIntrospection( "token=$token",
    "Basic " . encode_base64( "spa:anything", '' ) );
expectRefused( $res, 'Public client, Basic with an arbitrary secret',
    401, "unauthorized_client" );

# The response would give the identifier of the user for the calling RP
if ( $res->[0] == 200 ) {
    my $leak = from_json( $res->[2]->[0] );
    diag(   "Public client got sub=$leak->{sub} for a token of "
          . "$leak->{client_id}" );
}

# Public client, Basic authentication with an empty secret
$res =
  callIntrospection( "token=$token", "Basic " . encode_base64( "spa:", '' ) );
expectRefused( $res, 'Public client, Basic with an empty secret',
    401, "unauthorized_client" );

# Public client, client_secret_post with an arbitrary secret
$res = callIntrospection("token=$token&client_id=spa&client_secret=anything");
expectRefused( $res, 'Public client, client_secret_post',
    401, "unauthorized_client" );

# Public client, client_id only
$res = callIntrospection("token=$token&client_id=spa");
expectRefused( $res, 'Public client, client_id only',
    401, "unauthorized_client" );

# Public client with a registered secret: authenticated only with this secret
$json = expectJSON(
    callIntrospection(
        "token=$token", "Basic " . encode_base64( "pubsecret:pubsecret", "" )
    )
);
ok( $json->{active}, "Public client with its secret, Basic: token is active" );

$json = expectJSON(
    callIntrospection( "token=$token" . jwsAuth( "pubsecret", "pubsecret" ) ) );
ok( $json->{active},
    "Public client with its secret, client_secret_jwt: token is active" );

$res = callIntrospection( "token=$token",
    "Basic " . encode_base64( "pubsecret:wrong", "" ) );
expectRefused( $res, "Public client with a secret, Basic with a wrong secret",
    401, "invalid_client" );

$res = callIntrospection( "token=$token",
    "Basic " . encode_base64( "pubsecret:", "" ) );
expectRefused( $res, "Public client with a secret, Basic with an empty secret",
    401, "unauthorized_client" );

$res =
  callIntrospection("token=$token&client_id=pubsecret&client_secret=wrong");
expectRefused( $res,
    "Public client with a secret, client_secret_post with a wrong secret",
    400, "invalid_client" );

$res = callIntrospection( "token=$token" . jwsAuth( "pubsecret", "wrong" ) );
expectRefused( $res, "Public client with a secret, JWS signed with a wrong key",
    400, "invalid_client" );

$res = callIntrospection( "token=$token" . jwsAuth( "spa", "anything" ) );
expectRefused( $res, "Public client without secret, JWS",
    400, "invalid_client" );

clean_sessions();
done_testing();

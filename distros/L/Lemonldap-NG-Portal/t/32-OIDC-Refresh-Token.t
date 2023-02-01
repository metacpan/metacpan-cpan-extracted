use lib 'inc';
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

sub checkJWT {
    my ($access_token) = @_;
    my $payload = expectJWT(
        $access_token,
        iss       => "http://auth.op.com",
        name      => "Frédéric Accents",
        sub       => "french",
        scope     => "openid profile email",
        client_id => "rpid",
    );
    ok( grep { $_ eq "rpid" } @{ $payload->{aud} }, "rpid is in audience" );
    ok( grep { $_ eq "urn:extra2" } @{ $payload->{aud} },
        "additional audience found" );
    ok( grep { $_ eq "http://my.extra.audience/test" } @{ $payload->{aud} },
        "additional audience found" );
    cmp_ok( $payload->{exp}, ">", time + 1800, "Expiration date sanity check" );
    cmp_ok( $payload->{exp}, "<", time + 7200, "Expiration date sanity check" );
}

# Full test case
sub runTest {
    my ( $op, $jwt ) = @_;

    Time::Fake->reset;
    my ( $res, $query );
    my $idpId = login( $op, "french" );

    my $code = codeAuthorize(
        $op, $idpId,
        {
            response_type => "code",
            scope         => "openid profile email",
            client_id     => "rpid",
            state         => "af0ifjsldkj",
            redirect_uri  => "http://test/"
        }
    );

    my $json = expectJSON( codeGrant( $op, "rpid", $code, "http://test/" ) );
    my $access_token = $json->{access_token};
    checkJWT($access_token) if ($jwt);
    my $refresh_token = $json->{refresh_token};
    my $id_token      = $json->{id_token};
    ok( $access_token,  "Got access token" );
    ok( $refresh_token, "Got refresh token" );
    ok( $id_token,      "Got ID token" );

    my $id_token_payload = id_token_payload($id_token);
    is( $id_token_payload->{sub}, 'french', 'Found sub in ID token' );
    is(
        $id_token_payload->{name},
        'Frédéric Accents',
        'Found claim in ID token'
    );
    ok( ( grep { $_ eq "rpid" } @{ $id_token_payload->{aud} } ),
        'Check that clientid is in audience' );
    ok( (
            grep { $_ eq "http://my.extra.audience/test" }
              @{ $id_token_payload->{aud} }
        ),
        'Check for additional audiences'
    );
    ok( ( grep { $_ eq "urn:extra2" } @{ $id_token_payload->{aud} } ),
        'Check for additional audiences' );

    $json = expectJSON( getUserinfo( $op, $access_token ) );

    ok( $json->{'sub'} eq "french",            'Got User Info' );
    ok( $json->{'name'} eq "Frédéric Accents", 'Got User Info' );

    # Skip ahead in time
    Time::Fake->offset("+2h");

    # Verify access token is rejected
    $res = getUserinfo( $op, $access_token );
    is( $res->[0], 401, "Access token rejected" );

    # Refresh access token
    $json         = expectJSON( refreshGrant( $op, "rpid", $refresh_token ) );
    $access_token = $json->{access_token};
    checkJWT($access_token) if ($jwt);
    $id_token = $json->{id_token};
    ok( $access_token,                   "Got refreshed Access token" );
    ok( $id_token,                       "Got refreshed ID token" );
    ok( !defined $json->{refresh_token}, "Refresh token not present" );

    $id_token_payload = id_token_payload($id_token);
    is( $id_token_payload->{sub}, 'french', 'Found sub in ID token' );
    is(
        $id_token_payload->{name},
        'Frédéric Accents',
        'Found claim in ID token'
    );

    # Try refreshed access token
    $json = expectJSON( getUserinfo( $op, $access_token ) );

    ok( $json->{'sub'} eq "french",            'Got User Info' );
    ok( $json->{'name'} eq "Frédéric Accents", 'Got User Info' );

    # Check failure conditions
    $op->logout($idpId);

    # Refresh access token
    $res = refreshGrant( $op, "rpid", $refresh_token );
    expectReject( $res, 400, 'invalid_grant' );

    $res = getUserinfo( $op, $access_token );
    is( $res->[0], 401,
        "Cannot use refreshed access token tied to expired session" );

}

my $baseConfig = {
    ini => {
        logLevel                        => $debug,
        domain                          => 'op.com',
        portal                          => 'http://auth.op.com',
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
        oidcRPMetaDataOptions => {
            rp => {
                oidcRPMetaDataOptionsDisplayName         => "RP",
                oidcRPMetaDataOptionsClientID            => "rpid",
                oidcRPMetaDataOptionsAllowOffline        => 1,
                oidcRPMetaDataOptionsIDTokenSignAlg      => "HS512",
                oidcRPMetaDataOptionsAccessTokenSignAlg  => "RS512",
                oidcRPMetaDataOptionsAccessTokenClaims   => 1,
                oidcRPMetaDataOptionsClientSecret        => "rpid",
                oidcRPMetaDataOptionsUserIDAttr          => "",
                oidcRPMetaDataOptionsBypassConsent       => 1,
                oidcRPMetaDataOptionsRefreshToken        => 1,
                oidcRPMetaDataOptionsIDTokenForceClaims  => 1,
                oidcRPMetaDataOptionsAdditionalAudiences =>
                  "http://my.extra.audience/test urn:extra2",
            }
        },
        oidcServicePrivateKeySig => oidc_key_op_private_sig,
        oidcServicePublicKeySig  => oidc_cert_op_public_sig,
    }
};

my $op = LLNG::Manager::Test->new($baseConfig);
runTest($op);

# Re-run tests with JWT access tokens
$baseConfig->{ini}->{oidcRPMetaDataOptions}->{rp}
  ->{oidcRPMetaDataOptionsAccessTokenJWT} = 1;
$op = LLNG::Manager::Test->new($baseConfig);
runTest( $op, 1 );

clean_sessions();
done_testing();

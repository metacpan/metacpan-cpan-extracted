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

    # Use access_token to get an access token for rp2
    $query = buildForm( {
            grant_type    => 'urn:ietf:params:oauth:grant-type:token-exchange',
            client_id     => 'rpid',
            subject_token => $access_token,
            scope         => 'openid profile email',
            subject_token_type =>
              'urn:ietf:params:oauth:token-type:access_token',
            requested_token_type =>
              'urn:ietf:params:oauth:token-type:access_token',
        }
    );

    ok(
        $res = $op->_post(
            '/oauth2/token', IO::String->new($query),
            accept => 'application/json',
            length => length($query),
            custom =>
              { HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid:rpid"), }
        ),
        'Call /token with access_token'
    );

    # Refresh access token
    $json          = expectJSON($res);
    $access_token  = $json->{access_token};
    $id_token      = $json->{id_token};
    $refresh_token = $json->{refresh_token};
    ok( $access_token,  "Got refreshed Access token" );
    ok( $id_token,      "Got refreshed ID token" );
    ok( $refresh_token, "Got new refresh_token" );

    my $id_token_payload = id_token_payload($id_token);
    is( $id_token_payload->{sub}, 'french', 'Found sub in ID token' );
    is(
        $id_token_payload->{name},
        'Frédéric Accents',
        'Found claim in ID token'
    );
    ok( ( grep { $_ eq "rpid" } @{ $id_token_payload->{aud} } ),
        "rpid is in audience" );

    $json = expectJSON( getUserinfo( $op, $access_token ) );

    ok( $json->{'sub'} eq "french",            'Got User Info' );
    ok( $json->{'name'} eq "Frédéric Accents", 'Got User Info' );

    # Skip ahead in time again
    Time::Fake->offset("+4h");

    # Verify access token is rejected
    $res = getUserinfo( $op, $access_token );
    is( $res->[0], 401, "Access token rejected" );
}

my $baseConfig = {
    ini => {
        domain                          => 'op.com',
        portal                          => 'http://auth.op.com/',
        authentication                  => 'Demo',
        userDB                          => 'Same',
        issuerDBOpenIDConnectActivation => 1,
        oidcRPMetaDataExportedVars      => {
            rp => {
                email       => "mail",
                family_name => "cn",
                name        => "cn",
            },
            rp1 => {
                email       => "mail",
                family_name => "cn",
                name        => "cn",
            },
            rp2 => {
                email       => "mail",
                family_name => "cn",
                name        => "cn",
            },
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
                oidcRPMetaDataOptionsRedirectUris => 'http://test/',
                oidcRPMetaDataOptionsTokenXAuthorizedRP => 'rp',
            },
        },
        oidcServicePrivateKeySig => oidc_key_op_private_sig,
        oidcServicePublicKeySig  => oidc_cert_op_public_sig,
    }
};

my $op = LLNG::Manager::Test->new($baseConfig);
runTest($op);

clean_sessions();
done_testing();

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

my $debug = "error";

sub runTest {
    my ( $op, $jwt ) = @_;
    Time::Fake->reset;

    my $query;
    my $res;

    my $idpId = login( $op, 'french' );

    # Inital first name
    $Lemonldap::NG::Portal::UserDB::Demo::demoAccounts{french}->{cn} =
      'Frédéric Accents';

    my $code = codeAuthorize(
        $op, $idpId,
        {
            response_type => "code",

            # Include a weird scope name, to make sure they work (#2168)
            scope => "openid profile email offline_access !weird:scope.name~",
            client_id    => "rpid",
            state        => "af0ifjsldkj",
            redirect_uri => "http://test/"
        }
    );

    my $json = expectJSON( codeGrant( $op, "rpid", $code, "http://test/" ) );
    my $access_token = $json->{access_token};
    if ($jwt) {
        expectJWT(
            $access_token,
            name => "Frédéric Accents",
            sub  => "customfrench"
        );
    }
    my $refresh_token = $json->{refresh_token};
    my $id_token      = $json->{id_token};
    ok( $access_token,  "Got access token" );
    ok( $refresh_token, "Got refresh token" );
    ok( $id_token,      "Got ID token" );

    my $id_token_payload = id_token_payload($id_token);
    my $auth_time        = $id_token_payload->{auth_time};
    ok( $auth_time, "Authentication date found in token" );
    is(
        $id_token_payload->{name},
        'Frédéric Accents',
        'Found claim in ID token'
    );
    is( $id_token_payload->{sub}, 'customfrench', 'Found sub in ID token' );

    $json = expectJSON( getUserinfo( $op, $access_token ) );

    ok( $json->{'name'} eq "Frédéric Accents", 'Got User Info' );
    ok( $json->{'sub'} eq "customfrench",      'Got User Info' );

    $op->logout($idpId);

    # Refresh access token after logging out

    $json = expectJSON( refreshGrant( $op, 'rpid', $refresh_token ) );

    $access_token = $json->{access_token};
    if ($jwt) {
        expectJWT(
            $access_token,
            name => "Frédéric Accents",
            sub  => "customfrench"
        );
    }
    my $refresh_token2 = $json->{refresh_token};
    $id_token = $json->{id_token};
    ok( $access_token,            "Got refreshed Access token" );
    ok( $id_token,                "Got refreshed ID token" );
    ok( !defined $refresh_token2, "Refresh token not present" );

    $id_token_payload = id_token_payload($id_token);
    is(
        $id_token_payload->{name},
        'Frédéric Accents',
        'Found claim in ID token'
    );
    is( $id_token_payload->{sub}, 'customfrench', 'Found sub in ID token' );

    $json = expectJSON( getUserinfo( $op, $access_token ) );

    ok( $json->{name} eq "Frédéric Accents", "Correct user info" );
    ok( $json->{'sub'} eq "customfrench",    'Got User Info' );

    # Make sure offline session is still valid long after natural session
    # expiration time

    Time::Fake->offset("+10d");

    # Change attribute value
    $Lemonldap::NG::Portal::UserDB::Demo::demoAccounts{french}->{cn} =
      'Frédéric Freedom';

    $json = expectJSON( refreshGrant( $op, 'rpid', $refresh_token ) );

    $access_token = $json->{access_token};
    if ($jwt) {
        expectJWT(
            $access_token,
            name => "Frédéric Freedom",
            sub  => "customfrench"
        );
    }
    $refresh_token2 = $json->{refresh_token};
    $id_token       = $json->{id_token};
    ok( $access_token,            "Got refreshed Access token" );
    ok( $id_token,                "Got refreshed ID token" );
    ok( !defined $refresh_token2, "Refresh token not present" );

    $id_token_payload = id_token_payload($id_token);
    is( $id_token_payload->{auth_time},
        $auth_time, 'Original auth_time retained' );
    is(
        $id_token_payload->{name},
        'Frédéric Freedom',
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

    is( $json->{name},  "Frédéric Freedom", "Correct user info" );
    is( $json->{'sub'}, "customfrench",     'Got User Info' );

    ## Test introspection of refreshed token #2171
    $json = expectJSON( introspect( $op, 'rpid', $access_token ) );

    is( $json->{active},    1,      'Token is active' );
    is( $json->{client_id}, 'rpid', 'Introspection contains client_id' );
    is( $json->{sub},       'customfrench', 'Introspection contains sub' );

    # #2168
    ok(
        ( grep { $_ eq "!weird:scope.name~" } ( split /\s+/, $json->{scope} ) ),
        "Scope contains weird scope name"
    );
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
        oidcRPMetaDataMacros => {
            rp => {
                custom_sub => '"custom".$uid',
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
                oidcRPMetaDataOptionsUserIDAttr          => "custom_sub",
                oidcRPMetaDataOptionsBypassConsent       => 1,
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


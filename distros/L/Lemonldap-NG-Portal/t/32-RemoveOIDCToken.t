use warnings;
use Test::More;
use IO::String;
use JSON;
use Lemonldap::NG::Common::Session;

require 't/test-lib.pm';
require 't/oidc-lib.pm';

my $res;
my $json;
my $baseConfig = {
    ini => {
        logLevel                        => "error",
        domain                          => 'op.com',
        portal                          => 'http://auth.op.com/',
        authentication                  => 'Demo',
        timeoutActivity                 => 3600,
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
                oidcRPMetaDataOptionsRedirectUris => 'http://test/',
            }
        },
        oidcServicePrivateKeySig   => oidc_key_op_private_sig,
        oidcServicePublicKeySig    => oidc_cert_op_public_sig,
        oidcOfflineTokens          => 1,
        portalDisplayOfflineTokens => 1,
    }
};

sub runTest {
    my ($op) = @_;
    Time::Fake->reset;

    my $res;

    # Get code for RP1

    my $idpId = $op->login( 'dwho', { lmAuth => '1_Demo' } );
    my $code  = codeAuthorize(
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

    $json = expectJSON( codeGrant( $op, "rpid", $code, "http://test/" ) );
    my $access_token = $json->{access_token};
    if ($jwt) {
        expectJWT(
            $access_token,
            name => "Frédéric Accents",
            sub  => "customfrench"
        );
    }
    my $refresh_token = $json->{refresh_token};

    # Make sure refresh token session has no _lastSeen to avoid purge
    ok( !getSamlSession($refresh_token)->{data}->{_lastSeen} , "session has no _lastSeen");

    count(1);

    # First successful connection for 'dwho'

    ok(
        $res = $op->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        '1st "dwho" Auth query'
    );
    my $idd = expectCookie($res);
    expectRedirection( $res, 'http://auth.op.com/' );

    ok(
        $res = $op->_get(
            '/',
            cookie => "lemonldap=$idd",
            accept => 'text/html'
        ),
        'Get menu'
    );
    expectOK($res);

    ok( $res->[2]->[0] =~ qr%rpid%, 'OIDCI session displayed' )
      or explain( $res->[2]->[0], 'contains rpid in oidcOfflineTokens ' );

    my $returned_refresh_token;
    if ( $res->[2]->[0] =~ /"sessionid"\s*:\s*"([a-f0-9]{64})"/i ) {
        $returned_refresh_token = $1;
    }

    ok( $returned_refresh_token, "refresh token $returned_refresh_token exists in html" );

    ok(
        $res = $op->_delete(
            "/myoffline/$returned_refresh_token", cookie => "lemonldap=$idd",
        ),
        "Delete token $returned_refresh_token"
    );
    expectOK($res);

    ok(
        $res = $op->_get(
            '/',
            cookie => "lemonldap=$idd",
            accept => 'text/html'
        ),
        'Get menu'
    );
    expectOK($res);

    ok( $res->[2]->[0] !~ qr%rpid%, 'OIDCI session removed' )
      or
      explain( $res->[2]->[0], ' doesnt contains rpid in oidcOfflineTokens ' );

}

subtest "Run tests with base config" => sub {
    my $op = LLNG::Manager::Test->new($baseConfig);
    runTest($op);
};

clean_sessions();
done_testing();

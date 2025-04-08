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

sub checkJWT {
    my ( $access_token, $checkHdr, $isAt ) = @_;
    my $payload;
    $payload = expectJWT(
        $access_token,
        iss => "http://auth.op.com/",
        sub => "french",
    );
    ok( grep { $_ eq "rpid" } @{ $payload->{aud} }, "rpid is in audience" );
    my $hdrs = id_token_header($access_token);
    if ($checkHdr) {
        my $expectedTyp = $isAt ? 'at+JWT' : 'JWT';
        ok( $hdrs->{typ}, 'type header exists' )
          and ok( $hdrs->{typ} eq $expectedTyp, "Type is $expectedTyp" );
    }
    else {
        ok( !$hdrs->{typ}, 'No typ header' )
          or explain( $hdrs->{typ}, 'No typ' );
    }
}

# Full test case
sub runTest {
    my ( $op, $jwt, $jwtHeader ) = @_;

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
    my $id_token     = $json->{id_token};
    ok( $access_token, "Got access token" );
    ok( $id_token,     "Got ID token" );
    checkJWT( $access_token, $jwtHeader, 1 ) if ($jwt);
    checkJWT( $id_token,     $jwtHeader, 0 );

    $json = expectJSON( getUserinfo( $op, $access_token ) );

    ok( $json->{'sub'} eq "french",            'Got User Info' );
    ok( $json->{'name'} eq "Frédéric Accents", 'Got User Info' );

    # Skip ahead in time
    Time::Fake->offset("+2h");

    # Verify access token is rejected
    $res = getUserinfo( $op, $access_token );
    is( $res->[0], 401, "Access token rejected" );

}

my $baseConfig = {
    ini => {
        logLevel                        => $debug,
        domain                          => 'op.com',
        portal                          => 'http://auth.op.com/',
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
                oidcRPMetaDataOptionsDisplayName        => "RP",
                oidcRPMetaDataOptionsClientID           => "rpid",
                oidcRPMetaDataOptionsIDTokenSignAlg     => "RS256",
                oidcRPMetaDataOptionsAccessTokenSignAlg => "RS256",
                oidcRPMetaDataOptionsClientSecret       => "rpid",
                oidcRPMetaDataOptionsBypassConsent      => 1,
                oidcRPMetaDataOptionsRedirectUris       => 'http://test/',
            }
        },
        oidcServicePrivateKeySig => oidc_key_op_private_sig,
        oidcServicePublicKeySig  => oidc_cert_op_public_sig,
    }
};

my $op = LLNG::Manager::Test->new($baseConfig);

subtest "Run test with basic configuration" => sub {
    runTest( $op, 0, 1 );
};

subtest "Run test with JWT access tokens" => sub {
    $baseConfig->{ini}->{oidcRPMetaDataOptions}->{rp}
      ->{oidcRPMetaDataOptionsAccessTokenJWT} = 1;
    $op = LLNG::Manager::Test->new($baseConfig);
    runTest( $op, 1, 1 );
};

subtest "Run test with opaque token without headers" => sub {
    $baseConfig->{ini}->{oidcRPMetaDataOptions}->{rp}
      ->{oidcRPMetaDataOptionsAccessTokenJWT} = 0;
    $baseConfig->{ini}->{oidcRPMetaDataOptions}->{rp}
      ->{oidcRPMetaDataOptionsNoJwtHeader} = 1;
    $op = LLNG::Manager::Test->new($baseConfig);
    runTest( $op, 0, 0 );
};

subtest "Run test with JWT access tokens without headers" => sub {
    $baseConfig->{ini}->{oidcRPMetaDataOptions}->{rp}
      ->{oidcRPMetaDataOptionsAccessTokenJWT} = 1;
    $baseConfig->{ini}->{oidcRPMetaDataOptions}->{rp}
      ->{oidcRPMetaDataOptionsNoJwtHeader} = 1;
    $op = LLNG::Manager::Test->new($baseConfig);
    runTest( $op, 1, 0 );
};

clean_sessions();
done_testing();

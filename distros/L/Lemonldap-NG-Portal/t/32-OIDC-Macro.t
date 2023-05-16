use warnings;
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
my $res;

sub getAttributes {
    my ( $op, $login ) = @_;

    my $idpId = login( $op, "french" );
    my $code  = codeAuthorize(
        $op, $idpId,
        {
            response_type => "code",
            scope         => "openid profile email address extrascope",
            client_id     => "rpid",
            state         => "af0ifjsldkj",
            redirect_uri  => "http://rp.com/"
        }
    );

    my $tokenresp =
      expectJSON( codeGrant( $op, 'rpid', $code, "http://rp.com/" ) );
    ok( my $access_token = $tokenresp->{access_token}, 'Found access token' );
    ok( $res = getUserinfo( $op, $access_token ) );
    my $userinfo = expectJSON( getUserinfo( $op, $access_token ) );
    return $userinfo;
}

subtest "Macros, filtered by scope" => sub {

    # Initialization
    ok( my $op = op(), 'OP portal' );
    my $userinfo = getAttributes( $op, 'french' );

    is( $userinfo->{family_name}, 'Accents', 'Correct macro value' );
    is( $userinfo->{sub}, 'customfrench',    'Sub macro correctly evaluated' );
    is( $userinfo->{address}->{locality}, 'Someplace', 'Complex claim' );
    is(
        $userinfo->{inscope},
        'I am in scope',
        'Macro required by scope is included'
    );
    is( $userinfo->{notscope}, undef,
        'Macro not required by scope is omitted' );
};

subtest "Macros, not filtered by scope" => sub {

    # Initialization
    ok( my $op = op( oidcServiceIgnoreScopeForClaims => 1 ), 'OP portal' );
    my $userinfo = getAttributes( $op, 'french' );

    is( $userinfo->{family_name}, 'Accents', 'Correct macro value' );
    is( $userinfo->{sub}, 'customfrench',    'Sub macro correctly evaluated' );
    is( $userinfo->{address}->{locality}, 'Someplace', 'Complex claim' );
    is(
        $userinfo->{inscope},
        'I am in scope',
        'Macro required by scope is included'
    );
    is(
        $userinfo->{notscope},
        'I am not in scope',
        'Macro not required by scope is included'
    );
};

clean_sessions();
done_testing();

sub op {
    my (%conf) = @_;
    return LLNG::Manager::Test->new(
        {
            ini => {
                logLevel                        => $debug,
                domain                          => 'op.com',
                portal                          => 'http://auth.op.com',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => 1,
                issuerDBOpenIDConnectRule       => '$uid eq "french"',
                oidcRPMetaDataExportedVars      => {
                    rp => {
                        email       => "mail",
                        family_name => "extract_sn",
                        name        => "cn",
                        locality    => "locality",
                        inscope     => "mymacro_inscope",
                        notscope    => "mymacro_notscope",
                    }
                },
                oidcServiceAllowHybridFlow            => 1,
                oidcServiceAllowImplicitFlow          => 1,
                oidcServiceAllowAuthorizationCodeFlow => 1,
                oidcRPMetaDataOptionsExtraClaims      => {
                    rp => {
                        extrascope => "inscope",
                    },
                },
                oidcRPMetaDataMacros => {
                    rp => {
                        extract_sn       => '(split(/\s/, $cn))[1]',
                        custom_sub       => '"custom".$uid',
                        locality         => 'Someplace',
                        mymacro_inscope  => '"I am in scope"',
                        mymacro_notscope => '"I am not in scope"',
                    }
                },
                oidcRPMetaDataOptions => {
                    rp => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 1,
                        oidcRPMetaDataOptionsClientSecret      => "rpid",
                        oidcRPMetaDataOptionsUserIDAttr        => "custom_sub",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
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
                %conf,
            }
        }
    );
}


use warnings;
use Test::More;
use strict;
use IO::String;
use Hash::Merge::Simple qw/merge/;

# Initialization
my $res;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $debug = 'error';

sub getop {
    my ($override) = @_;
    return register( 'op', sub { op($override) } );
}

sub getIDTokenParts {
    my ($op) = @_;

    my $idpId = login( $op, "french" );
    my $code  = codeAuthorize(
        $op, $idpId,
        {
            response_type => "code",
            scope         => "openid profile email",
            client_id     => "rpid",
            state         => "af0ifjsldkj",
            redirect_uri  => "http://rp.com/"
        }
    );

    my $tokenresp =
      expectJSON( codeGrant( $op, 'rpid', $code, "http://rp.com/" ) );
    my $id_token         = $tokenresp->{id_token};
    my $id_token_header  = id_token_header($id_token);
    my $id_token_payload = id_token_payload($id_token);
    ok( $id_token_header,  "Successfully decoded ID Token header" );
    ok( $id_token_payload, "Successfully decoded ID Token payload" );
    return ( $id_token_header, $id_token_payload );
}

subtest "Default ID token" => sub {
    my $op = getop;

    my ( $header, $payload ) = getIDTokenParts($op);

    is( $header->{alg},       "RS256", "Default ID token alg is RS256" );
    is( $header->{kid},       undef,   "kid is not present" );
    is( $payload->{aud}->[0], "rpid",  "Audience is rpid" );
    ok( ( $payload->{exp} - time ) > 3000, "Expires in an hour" );
    is( $payload->{iss},   "http://auth.op.com/", "Issuer is correct" );
    is( $payload->{sub},   "french",              "Subject is correct" );
    is( $payload->{email}, undef,                 "No claims in ID Token" );
    ok( !exists $payload->{amr}, "No amr set" );
};

subtest "Custom AMR rule" => sub {
    my $op = getop( {
            oidcServiceMetaDataAmrRules => {
                myamr  => '$uid eq "french"',
                cigood => '$_clientId eq "rpid"',
                ckgood => '$_clientConfKey eq "rp"',
                cibad  => '$_clientId eq "rpid2"',
                ckbad  => '$_clientConfKey eq "rp2"',
            }
        }
    );

    my ( $header, $payload ) = getIDTokenParts($op);
    is_deeply(
        [ sort @{ $payload->{amr} } ],
        [qw/cigood ckgood myamr/],
        "Correct AMR values found"
    );
};

subtest "Has Key ID in conf" => sub {
    my $op = getop( {
            oidcServiceKeyIdSig => "xxxyy",
        }
    );

    my ( $header, $payload ) = getIDTokenParts($op);

    is( $header->{alg}, "RS256", "Default ID token alg is RS256" );
    is( $header->{kid}, "xxxyy", "kid is correct" );
};

subtest "Different signing alg" => sub {
    my $op = getop( {
            oidcRPMetaDataOptions => {
                rp => {
                    oidcRPMetaDataOptionsIDTokenSignAlg => "HS256",
                }
            }
        }
    );
    my ( $header, $payload ) = getIDTokenParts($op);
    is( $header->{alg}, "HS256", "Signature alg was modified" );
    is( $header->{kid}, undef,   "kid is not present" );
};

subtest "Force claims" => sub {
    my $op = getop( {
            oidcRPMetaDataOptions => {
                rp => {
                    oidcRPMetaDataOptionsIDTokenForceClaims => 1,
                }
            }
        }
    );
    my ( $header, $payload ) = getIDTokenParts($op);
    is( $payload->{email}, 'fa@badwolf.org', "Found claims in ID Token" );
};

clean_sessions();
done_testing();

sub op {
    my ($override) = @_;
    return LLNG::Manager::Test->new( {
            ini => merge( {
                    logLevel                        => $debug,
                    domain                          => 'idp.com',
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
                    oidcServiceAllowHybridFlow            => 1,
                    oidcServiceAllowImplicitFlow          => 1,
                    oidcServiceAllowAuthorizationCodeFlow => 1,
                    oidcRPMetaDataOptions                 => {
                        rp => {
                            oidcRPMetaDataOptionsDisplayName       => "RP",
                            oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                            oidcRPMetaDataOptionsClientID          => "rpid",
                            oidcRPMetaDataOptionsClientSecret      => "rpid",
                            oidcRPMetaDataOptionsIDTokenSignAlg    => "RS256",
                            oidcRPMetaDataOptionsBypassConsent     => 0,
                            oidcRPMetaDataOptionsUserIDAttr        => "",
                            oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                            oidcRPMetaDataOptionsBypassConsent         => 1,
                            oidcRPMetaDataOptionsRedirectUris          =>
                              "http://rp.com/",
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
                },
                $override
            )
        }
    );
}

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
my $res;

# Helper to post registration data
sub post_register {
    my ( $op, $data ) = @_;
    my $json = JSON::to_json($data);
    return $op->_post(
        "/oauth2/register",
        IO::String->new($json),
        accept => 'application/json',
        length => length($json),
    );
}

# Helper to find the latest config file for a registered RP
sub get_registered_rp_conf {
    my ($conf_num) = @_;
    $conf_num //= 2;

    # Try requested number first, then fall back
    my $confFile;
    for my $n ( $conf_num, $conf_num - 1, $conf_num + 1 ) {
        my $f = "$main::tmpDir/lmConf-$n.json";
        if ( -f $f ) {
            $confFile = $f;
            last;
        }
    }
    die "No config file found" unless $confFile;
    my $conf = JSON::from_json(`cat $confFile`);
    my $rpId =
      ( grep { /^register-/ } keys %{ $conf->{oidcRPMetaDataOptions} } )[0];
    return ( $conf, $rpId, $confFile );
}

subtest "Confidential only mode (value=1)" => sub {

    ok( my $op = op(1), 'OP portal' );

    subtest "client_secret_basic registration" => sub {
        $res = post_register(
            $op,
            {
                application_type         => "web",
                redirect_uris            => [
                    "https://client.example.org/callback",
                    "https://client.example.org/callback2"
                ],
                client_name                => "My Example",
                logo_uri                   => "https://client.example.org/logo.png",
                subject_type               => "pairwise",
                token_endpoint_auth_method => "client_secret_basic",
            }
        );
        ok( $res->[0] == 201, "Return code is 201" );
        my $answer = JSON::from_json( $res->[2]->[0] );

        ok( defined $answer->{client_id},     "client_id in response" );
        ok( defined $answer->{client_secret},  "client_secret in response" );
        is( $answer->{token_endpoint_auth_method}, 'client_secret_basic',
            "token_endpoint_auth_method in response" );

        my ( $conf, $rpId, $confFile ) = get_registered_rp_conf(2);
        is( $conf->{oidcRPMetaDataOptions}->{$rpId}
              ->{oidcRPMetaDataOptionsClientID},
            $answer->{client_id}, "Client ID saved in configuration" );
        is( $conf->{oidcRPMetaDataOptionsExtraClaims}->{$rpId}
              ->{"extra_claim"},
            "extra_var", "Extra claim defined" );
        is( $conf->{oidcRPMetaDataExportedVars}->{$rpId}->{"extra_var"},
            "mail", "Extra variable defined" );
        is( $conf->{oidcRPMetaDataOptions}->{$rpId}
              ->{oidcRPMetaDataOptionsRequirePKCE},
            2, "RequirePKCE set to 2 (pkceOrSecret)" );
        unlink $confFile;
    };

    subtest "public client rejected" => sub {
        $res = post_register(
            $op,
            {
                redirect_uris            => ["https://client.example.org/callback"],
                client_name                => "Public Client",
                token_endpoint_auth_method => "none",
            }
        );
        is( $res->[0], 400, "Public client rejected" );
    };

    subtest "private_key_jwt rejected" => sub {
        $res = post_register(
            $op,
            {
                redirect_uris            => ["https://client.example.org/callback"],
                client_name                => "PKJ Client",
                token_endpoint_auth_method => "private_key_jwt",
                jwks_uri                   => "https://client.example.org/jwks",
            }
        );
        is( $res->[0], 400, "private_key_jwt rejected" );
    };

    subtest "unsupported auth method rejected" => sub {
        $res = post_register(
            $op,
            {
                redirect_uris            => ["https://client.example.org/callback"],
                client_name                => "Bad Method",
                token_endpoint_auth_method => "tls_client_auth",
            }
        );
        is( $res->[0], 400, "Unsupported method rejected" );
    };
};

reset_tmpdir();

subtest "All clients mode (value=2)" => sub {

    ok( my $op = op(2), 'OP portal' );

    subtest "public client accepted" => sub {
        $res = post_register(
            $op,
            {
                redirect_uris            => ["https://client.example.org/callback"],
                client_name                => "Public Client",
                token_endpoint_auth_method => "none",
            }
        );
        is( $res->[0], 201, "Public client accepted" );
        my $answer = JSON::from_json( $res->[2]->[0] );

        ok( !defined $answer->{client_secret}, "No client_secret" );
        is( $answer->{token_endpoint_auth_method}, 'none',
            "token_endpoint_auth_method=none" );

        my ( $conf, $rpId, $confFile ) = get_registered_rp_conf(2);
        is( $conf->{oidcRPMetaDataOptions}->{$rpId}
              ->{oidcRPMetaDataOptionsPublic},
            1, "Public flag set" );
        is( $conf->{oidcRPMetaDataOptions}->{$rpId}
              ->{oidcRPMetaDataOptionsRequirePKCE},
            2, "RequirePKCE set to 2" );
        unlink $confFile;
    };

    subtest "private_key_jwt without jwks_uri rejected" => sub {
        $res = post_register(
            $op,
            {
                redirect_uris            => ["https://client.example.org/callback"],
                client_name                => "PKJ No JWKS",
                token_endpoint_auth_method => "private_key_jwt",
            }
        );
        is( $res->[0], 400, "Rejected without jwks_uri" );
    };

    subtest "private_key_jwt with jwks_uri accepted" => sub {
        $res = post_register(
            $op,
            {
                redirect_uris            => ["https://client.example.org/callback"],
                client_name                => "PKJ Client",
                token_endpoint_auth_method => "private_key_jwt",
                jwks_uri                   => "https://client.example.org/jwks",
            }
        );
        is( $res->[0], 201, "Accepted with jwks_uri" );
        my $answer = JSON::from_json( $res->[2]->[0] );

        ok( !defined $answer->{client_secret}, "No client_secret" );
        is( $answer->{token_endpoint_auth_method}, 'private_key_jwt',
            "token_endpoint_auth_method=private_key_jwt" );

        my ( $conf, $rpId, $confFile ) = get_registered_rp_conf(3);
        is( $conf->{oidcRPMetaDataOptions}->{$rpId}
              ->{oidcRPMetaDataOptionsJwksUri},
            'https://client.example.org/jwks', "jwks_uri saved" );
        ok( !$conf->{oidcRPMetaDataOptions}->{$rpId}
              ->{oidcRPMetaDataOptionsPublic},
            "Not marked as public" );
    };

    subtest "client_secret_jwt generates a secret" => sub {
        $res = post_register(
            $op,
            {
                redirect_uris            => ["https://client.example.org/callback"],
                client_name                => "CS JWT Client",
                token_endpoint_auth_method => "client_secret_jwt",
            }
        );
        is( $res->[0], 201, "Accepted" );
        my $answer = JSON::from_json( $res->[2]->[0] );

        ok( defined $answer->{client_secret}, "client_secret present" );
        is( $answer->{token_endpoint_auth_method}, 'client_secret_jwt',
            "token_endpoint_auth_method=client_secret_jwt" );
    };
};

clean_sessions();
done_testing();

sub op {
    my ($dynreg_level) = @_;
    $dynreg_level //= 1;
    return LLNG::Manager::Test->new( {
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
                        family_name => "extract_sn",
                        name        => "cn"
                    }
                },
                oidcServiceDynamicRegistrationExportedVars =>
                  { "extra_var" => "mail" },
                oidcServiceDynamicRegistrationExtraClaims =>
                  { "extra_claim" => "extra_var" },
                oidcServiceAllowHybridFlow            => 1,
                oidcServiceAllowImplicitFlow          => 1,
                oidcServiceAllowDynamicRegistration   => $dynreg_level,
                oidcServiceAllowAuthorizationCodeFlow => 1,
                oidcRPMetaDataMacros                  => {
                    rp => {
                        extract_sn => '(split(/\s/, $cn))[1]',
                    }
                },
                oidcRPMetaDataOptions => {
                    rp => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 1,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
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
            }
        }
    );
}

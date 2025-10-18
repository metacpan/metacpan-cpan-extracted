use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use Time::Fake;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/saml-lib.pm';
    require 't/oidc-lib.pm';
}

sub getinstances {
    my ($client) = @_;
    ok(
        my $i_saml =
          $client->p->loadedModules->{'Lemonldap::NG::Portal::Issuer::SAML'},
        'Found SAML issuer instance'
    );
    ok(
        my $i_oidc = $client->p->loadedModules->{
            'Lemonldap::NG::Portal::Issuer::OpenIDConnect'},
        'Found OIDC issuer instance'
    );
    ok( my $mock = $client->p->loadedModules->{'t::HookMock'},
        'Found mock instance' );
    return ( $i_saml, $i_oidc, $mock );
}

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found';
    }
    my $client = LLNG::Manager::Test->new( {
            ini => {
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBSAMLActivation          => 1,
                issuerDBOpenIDConnectActivation => "1",
                samlServicePrivateKeyEnc        => saml_key_idp_private_enc,
                samlServicePrivateKeySig        => saml_key_idp_private_sig,
                samlServicePublicKeyEnc         => saml_key_idp_public_enc,
                samlServicePublicKeySig         => saml_key_idp_public_sig,
                oidcServicePrivateKeySig        => oidc_key_op_private_sig,
                oidcServicePublicKeySig         => oidc_cert_op_public_sig,
                customPlugins                   => 't::HookMock',
            }
        }
    );

    subtest "no TTL, not called again" => sub {
        Time::Fake->reset();
        $client->p->HANDLER->checkConf(1);
        my ( $i_saml, $i_oidc, $mock ) = getinstances($client);
        is( $i_oidc->getRP('test'), undef, "test not found" );
        is( $mock->count,           1,     "Hook was called once" );

        $i_saml->lazy_load_entityid("test");
        is( $mock->count, 2, "Hook was called twice" );

        is( $i_oidc->getRP('test'), undef, "test not found" );
        $i_saml->lazy_load_entityid("test");
        is( $mock->count, 2, "Hook was not called again" );
    };

    subtest "no TTL, error result, called again" => sub {
        Time::Fake->reset();
        $client->p->HANDLER->checkConf(1);
        my ( $i_saml, $i_oidc, $mock ) = getinstances($client);

        # First call returns an error
        $mock->mock_result(24);

        is( $i_oidc->getRP('test'), undef, "test not found" );
        is( $mock->count,           1,     "Hook was called once" );

        $i_saml->lazy_load_entityid("test");
        is( $mock->count, 2, "Hook was called twice" );

        # Second call is successful
        $mock->mock_result(0);
        is( $i_oidc->getRP('test'), undef, "test not found" );
        $i_saml->lazy_load_entityid("test");
        is( $mock->count, 4, "Hook was called again" );

        # Next try does not call hook
        is( $i_oidc->getRP('test'), undef, "test not found" );
        $i_saml->lazy_load_entityid("test");
        is( $mock->count, 4, "Hook was not called again" );
    };

    subtest "TTL, called again after TTL" => sub {
        Time::Fake->reset();
        $client->p->HANDLER->checkConf(1);
        my ( $i_saml, $i_oidc, $mock ) = getinstances($client);
        $mock->mock_info( { ttl => 600 } );

        is( $i_oidc->getRP('test'), undef, "test not found" );
        is( $mock->count,           1,     "Hook was called once" );

        $i_saml->lazy_load_entityid("test");
        is( $mock->count, 2, "Hook was called twice" );

        Time::Fake->offset('+500s');
        is( $i_oidc->getRP('test'), undef, "test not found" );
        $i_saml->lazy_load_entityid("test");
        is( $mock->count, 2, "Hook was not called again" );

        Time::Fake->offset('+900s');
        is( $i_oidc->getRP('test'), undef, "test not found" );
        $i_saml->lazy_load_entityid("test");
        is( $mock->count, 4, "Hook was called again" );
    };
}

clean_sessions();
done_testing();

# Must be in a BEGIN block for Mouse to work
BEGIN {

    package t::HookMock;
    use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);
    use Mouse;

    has count       => ( is => 'rw', default => '0' );
    has mock_result => ( is => 'rw', default => PE_OK );
    has mock_info   => ( is => 'rw', default => sub { {} } );
    use constant hook => {
        getSamlConfig   => 'configHook',
        getOidcRpConfig => 'configHook',
    };

    extends 'Lemonldap::NG::Portal::Main::Plugin';

    sub configHook {
        my ( $self, $req, $key, $config ) = @_;
        $self->count( $self->count + 1 );
        %$config = %{ $self->mock_info };
        return $self->mock_result;
    }
    1;
}

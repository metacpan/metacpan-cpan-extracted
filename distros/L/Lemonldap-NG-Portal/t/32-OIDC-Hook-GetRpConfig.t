use warnings;
no warnings 'once';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use Crypt::JWT qw(encode_jwt);
use JSON;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $debug = 'error';

# Initialization
my ( $res, $query );

subtest "Check negative TTL" => sub {
    my $op    = op();
    my $idpId = $op->login("french");
    Time::Fake->reset;
    plugin($op)->confEnabled(0);

    authorizeFails( $op, $idpId, 107 );
    is( plugin($op)->callCount, 1, "Called once" );

    Time::Fake->offset("+5m");
    authorizeFails( $op, $idpId, 107 );
    is( plugin($op)->callCount, 1, "Not called again" );

    Time::Fake->offset("+15m");
    authorizeFails( $op, $idpId, 107 );
    is( plugin($op)->callCount, 2, "Called again" );

};

subtest "Check getting RP from plugin" => sub {
    my $op    = op();
    my $idpId = $op->login("french");
    Time::Fake->reset;

    # Call with wrong parameters, this fails but load config
    authorizeFails( $op, $idpId, 108, { redirect_uri => 'http://hook.org/' } );
    is( plugin($op)->callCount, 1, "Called once" );

    # Call with correct parameters, config already loaded
    my $code = authorizeWorks( $op, $idpId );
    is( plugin($op)->callCount, 1, "Not called again" );

    # Exchange code for AT
    $res = codeGrant( $op, 'hookclient', $code, 'http://hook.com/' );

    my $json  = from_json( $res->[2]->[0] );
    my $token = $json->{access_token};
    ok( $token, 'Access token present' );

    $res  = getUserinfo( $op, $token );
    $json = expectJSON($res);
    is(
        $json->{fullname},
        "I am Frédéric Accents",
        "Scope, Attributes etc are working"
    );
};

subtest "Check config change" => sub {
    my $op    = op();
    my $idpId = $op->login("french");
    Time::Fake->reset;

    is( get_id_token_alg( $op, $idpId ), "HS512" );
    is( plugin($op)->callCount, 1, "Called once" );

    plugin($op)->alg("RS256");

    is( get_id_token_alg( $op, $idpId ), "HS512" );
    is( plugin($op)->callCount, 1, "Not called again yet" );

    Time::Fake->offset("+1h");
    is( get_id_token_alg( $op, $idpId ), "RS256" );
    is( plugin($op)->callCount, 2, "Called again" );
};

subtest "Test persistent behavior" => sub {
    my $op    = op();
    my $idpId = $op->login("french");
    Time::Fake->reset;

    # Load config
    authorizeWorks( $op, $idpId );
    is( plugin($op)->callCount, 1, "Plugin was called" );

    subtest "After disabling config, provider is becomes disabled" => sub {
        plugin($op)->confEnabled(0);

        authorizeWorks( $op, $idpId );
        is( plugin($op)->callCount, 1, "Plugin was not called again" );

        # Wait to make sure TTL is expired
        Time::Fake->offset("+1h");

        authorizeFails( $op, $idpId, 107 );
        is( plugin($op)->callCount, 2, "Plugin was called again" );
    };

    subtest "After reload, config is disabled for good" => sub {

        # Config reload
        $op->p->HANDLER->checkConf(1);
        plugin($op)->confEnabled(0);
        is( plugin($op)->callCount, 0, "Call count reset" );

        # Provider is no longer known
        authorizeFails( $op, $idpId, 107 );
        is( plugin($op)->callCount, 1, "Plugin was called" );
    };

    subtest "Enable again, reload, config works immediately" => sub {

        # Config reload before negative TTL expiration
        $op->p->HANDLER->checkConf(1);
        is( plugin($op)->callCount, 0, "Call count reset" );

        # Provider is known again because config was reloaded
        authorizeWorks( $op, $idpId );
        is( plugin($op)->callCount, 1, "Plugin was called" );
    };
};

subtest "Make sure token endpoint loads RP" => sub {
    subtest "client id + password" => sub {
        my $op  = op();
        my $res = $op->_post(
            "/oauth2/token",
            {
                grant_type    => "client_credentials",
                client_id     => 'hookclient',
                client_secret => 'hookclient',
                scope         => "openid",
            }
        );
        my $json = expectJSON($res);
        ok( $json->{access_token}, "Found access token" );
    };

    subtest "JWT auth" => sub {
        my $op = op();

        my $key = oidc_key_op_private_sig;
        my $jwt = encode_jwt(
            payload => {
                iss => "hookclient",
                sub => "hookclient",
                aud => "auth.example.com",
                exp => ( time + 100 ),
            },
            alg => "RS256",
            key => \$key,
        );

        my $res = $op->_post(
            "/oauth2/token",
            {
                grant_type            => "client_credentials",
                client_id             => "hookclient",
                client_assertion_type =>
                  'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
                client_assertion => $jwt,
                scope            => "openid",
            }
        );
        my $json = expectJSON($res);
        ok( $json->{access_token}, "Found access token" );
    };
};

sub authorizeWorks {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $op, $idpId, $params ) = @_;
    my $code = codeAuthorize(
        $op, $idpId,
        {
            response_type => 'code',
            scope         => 'openid',
            client_id     => 'hookclient',
            state         => 1234,
            redirect_uri  => 'http://hook.com/',
            %{ $params || {} },
        }
    );
    ok( $code, "Found code" );
    return $code;
}

sub authorizeFails {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $op, $idpId, $err, $params ) = @_;
    my $res = authorize(
        $op, $idpId,
        {
            response_type => 'code',
            scope         => 'openid',
            client_id     => 'hookclient',
            state         => 1234,
            redirect_uri  => 'http://hook.com/',
            %{ $params || {} },
        }
    );
    expectPortalError( $res, $err );
}

sub get_id_token_alg {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $op, $idpId ) = @_;

    my $code = authorizeWorks( $op, $idpId );

    # get ID token
    my $res = codeGrant( $op, 'hookclient', $code, 'http://hook.com/' );

    my $json     = from_json( $res->[2]->[0] );
    my $id_token = $json->{id_token};
    ok( $id_token, 'ID token present' );

    my $header = id_token_header($id_token);
    return $header->{alg};
}

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'idp.com',
                portal                          => 'http://auth.op.com/',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => 1,
                oidcServiceIgnoreScopeForClaims => 0,
                oidcServicePrivateKeySig        => oidc_key_op_private_sig,
                oidcServicePublicKeySig         => oidc_cert_op_public_sig,
                customPlugins                   => 't::OidcHookPlugin',
            }
        }
    );
}

sub plugin {
    my ($op) = @_;
    return $op->p->loadedModules->{'t::OidcHookPlugin'};
}

clean_sessions();
done_testing();

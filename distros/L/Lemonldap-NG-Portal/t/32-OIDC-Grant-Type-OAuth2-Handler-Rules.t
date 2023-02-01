use Test::More;
use strict;
use IO::String;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_FIRSTACCESS
);

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $res;
my $debug = "error";

# Handler part
use_ok('Lemonldap::NG::Handler::Server');
use_ok('Lemonldap::NG::Common::PSGI::Cli::Lib');
count(2);

my ( $handler, $portal );
$portal  = portal();
$handler = Lemonldap::NG::Handler::Server->run( $portal->ini );

my $access_token;

$access_token = get_access_token_client($portal);

expectOK( handler_req( $handler, '/clientonly', $access_token ) );
expectForbidden( handler_req( $handler, '/passwordonly', $access_token ), 403 );
expectForbidden( handler_req( $handler, '/codeonly',     $access_token ), 403 );

$access_token = get_access_token_password($portal);

expectForbidden( handler_req( $handler, '/clientonly', $access_token ) );
expectOK( handler_req( $handler, '/passwordonly', $access_token ), 403 );
expectForbidden( handler_req( $handler, '/codeonly', $access_token ), 403 );

$access_token = get_access_token_code($portal);

expectForbidden( handler_req( $handler, '/clientonly',   $access_token ) );
expectForbidden( handler_req( $handler, '/passwordonly', $access_token ), 403 );
expectOK( handler_req( $handler, '/codeonly', $access_token ), 403 );

clean_sessions();

done_testing( count() );

sub handler_req {
    my ( $handler, $url, $access_token ) = @_;
    return $handler->( {
            'HTTP_ACCEPT'          => 'text/html',
            'SCRIPT_NAME'          => $url,
            'SERVER_NAME'          => '127.0.0.1',
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'PATH_INFO'            => $url,
            'REQUEST_METHOD'       => 'GET',
            'REQUEST_URI'          => $url,
            'X_ORIGINAL_URI'       => $url,
            'SERVER_PORT'          => '80',
            'SERVER_PROTOCOL'      => 'HTTP/1.1',
            'HTTP_USER_AGENT'      =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'REMOTE_ADDR'        => '127.0.0.1',
            'HTTP_HOST'          => 'oauth.example.com',
            'HTTP_AUTHORIZATION' => "Bearer $access_token",
        }
    );
}

sub get_access_token_client {
    my ($portal) = @_;
    my $query = buildForm( {
            client_id     => 'rpid',
            client_secret => 'rpid',
            grant_type    => 'client_credentials',
            scope         => 'profile',
        }
    );

    ## Get Access Token with Client Credentials
    my $res = $portal->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'application/json',
        length => length($query),
    );

    $res = expectJSON($res);
    return $res->{access_token};
}

sub get_access_token_password {
    my ($portal) = @_;
    ## Get Access Token with Password Grant
    my $query = buildForm( {
            client_id     => 'rpid',
            client_secret => 'rpid',
            grant_type    => 'password',
            username      => 'dwho',
            password      => 'dwho',
            scope         => 'profile',
        }
    );
    my $res = $portal->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'application/json',
        length => length($query),
    );

    $res = expectJSON($res);
    my $access_token = $res->{access_token};
}

sub get_access_token_code {
    my ($portal) = @_;

    my $id = login( $portal, 'dwho' );

    my $code = codeAuthorize(
        $portal, $id,
        {
            response_type => "code",

            # Include a weird scope name, to make sure they work (#2168)
            scope        => "openid profile",
            client_id    => "rpid",
            state        => "af0ifjsldkj",
            redirect_uri => "http://test"
        }
    );

    my $res = codeGrant( $portal, 'rpid', $code, 'http://test' );
    $res = expectJSON($res);
    return $res->{access_token};
}

sub portal {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                           => $debug,
                domain                             => 'op.com',
                portal                             => 'http://auth.op.com',
                authentication                     => 'Demo',
                userDB                             => 'Same',
                issuerDBOpenIDConnectActivation    => 1,
                oidcServiceAllowOnlyDeclaredScopes => 1,
                vhostOptions                       => {
                    'oauth.example.com' => {
                        'vhostType' => 'OAuth2'
                    },
                },
                locationRules => {
                    'auth.example.com' => {
                        default => 'accept',
                    },
                    'oauth.example.com' => {
                        '(?#Client Only)^/clientonly' =>
                          '$_oidc_grant_type eq "clientcredentials"',
                        '(?#Code Only)^/codeonly' =>
                          '$_oidc_grant_type eq "authorizationcode"',
                        '(?#Password Only)^/passwordonly' =>
                          '$_oidc_grant_type eq "password"',
                        'default' => 'deny',
                    },
                },
                oidcRPMetaDataExportedVars => {
                    rp => {
                        email       => "mail",
                        family_name => "cn",
                        name        => "cn"
                    },
                },
                oidcRPMetaDataOptions => {
                    rp => {
                        oidcRPMetaDataOptionsDisplayName           => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                        oidcRPMetaDataOptionsClientID              => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                        oidcRPMetaDataOptionsClientSecret          => "rpid",
                        oidcRPMetaDataOptionsUserIDAttr            => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsBypassConsent         => 1,
                        oidcRPMetaDataOptionsAllowClientCredentialsGrant => 1,
                        oidcRPMetaDataOptionsAllowPasswordGrant          => 1,
                        oidcRPMetaDataOptionsRedirectUris => "http://test",
                    },
                },
                oidcServicePrivateKeySig => oidc_key_op_private_sig,
                oidcServicePublicKeySig  => oidc_cert_op_public_sig,
            }
        }
    );
}

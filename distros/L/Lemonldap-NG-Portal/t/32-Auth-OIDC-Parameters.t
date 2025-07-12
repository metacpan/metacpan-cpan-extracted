use warnings;
use Test::More;
use strict;
use URI::QueryParam;
use URI;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $metadata = <<EOF;
{
  "authorization_endpoint": "https://op.example.com/oauth2/authorize",
  "issuer": "https://op.example.com/",
  "jwks_uri": "https://op.example.com/oauth2/jwks",
  "token_endpoint": "https://op.example.com/oauth2/token",
  "userinfo_endpoint": "https://op.example.com/oauth2/userinfo"
}
EOF

use Lemonldap::NG::Portal::Main::Request;
my $rp = rp($metadata);

ok( my $oidc = $rp->p->_authentication );

sub checkRequestParams {
    my ( $extra_options, $expected_result ) = @_;

    my $backup_options = $oidc->opOptions->{"op"};

    $oidc->opOptions->{"op"} = { %$backup_options, %{ $extra_options // {} } };

    my $req = Lemonldap::NG::Portal::Main::Request->new(
        { REQUEST_URI => "/", PATH_INFO => "/" } );
    $req->portal("http://auth.example.com");
    my $u = URI->new(
        $oidc->buildAuthorizationCodeAuthnRequest( $req, "op", "123", "456" ) );

    is_deeply( $u->query_form_hash, $expected_result );

    $oidc->opOptions->{"op"} = $backup_options;
}

# Default parameters
checkRequestParams(
    undef,
    {
        'client_id'     => 'rpid',
        'redirect_uri'  => 'http://auth.example.com?openidconnectcallback=1',
        'response_type' => 'code',
        'state'         => '123',
        'nonce'         => '456',
        'scope'         => 'openid profile email'
    }
);

# Empty values are not added
checkRequestParams( {
        oidcOPMetaDataOptionsDisplay => "",
        oidcOPMetaDataOptionsPrompt  => "",

        # MaxAge == 0 means no max age (see #3429)
        oidcOPMetaDataOptionsMaxAge    => 0,
        oidcOPMetaDataOptionsUiLocales => "",
        oidcOPMetaDataOptionsAcrValues => "",
    },
    {
        'client_id'     => 'rpid',
        'redirect_uri'  => 'http://auth.example.com?openidconnectcallback=1',
        'response_type' => 'code',
        'state'         => '123',
        'nonce'         => '456',
        'scope'         => 'openid profile email',
    }
);

# Non empty values are added
checkRequestParams( {
        oidcOPMetaDataOptionsDisplay   => "mydisplay",
        oidcOPMetaDataOptionsPrompt    => "myprompt",
        oidcOPMetaDataOptionsMaxAge    => 30,
        oidcOPMetaDataOptionsUiLocales => "mylocales",
        oidcOPMetaDataOptionsAcrValues => "myvalue1 myvalue2",
    },
    {
        'client_id'     => 'rpid',
        'redirect_uri'  => 'http://auth.example.com?openidconnectcallback=1',
        'response_type' => 'code',
        'state'         => '123',
        'nonce'         => '456',
        'scope'         => 'openid profile email',
        'ui_locales'    => 'mylocales',
        'prompt'        => 'myprompt',
        'display'       => 'mydisplay',
        'acr_values'    => 'myvalue1 myvalue2',
        'max_age'       => 30,
    }
);

clean_sessions();
done_testing();

sub rp {
    my ($metadata) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                domain                     => 'rp.com',
                portal                     => 'http://auth.rp.com/',
                authentication             => 'OpenIDConnect',
                userDB                     => 'Same',
                restSessionServer          => 1,
                restExportSecretKeys       => 1,
                oidcOPMetaDataExportedVars => {
                    op => {
                        cn     => "name",
                        uid    => "sub",
                        sn     => "family_name",
                        mail   => "email",
                        groups => "groups",
                    }
                },
                oidcOPMetaDataOptions => {
                    op => {
                        oidcOPMetaDataOptionsCheckJWTSignature => 1,
                        oidcOPMetaDataOptionsJWKSTimeout       => 100,
                        oidcOPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcOPMetaDataOptionsScope => "openid profile email",
                        oidcOPMetaDataOptionsStoreIDToken     => 0,
                        oidcOPMetaDataOptionsDisplay          => "",
                        oidcOPMetaDataOptionsClientID         => "rpid",
                        oidcOPMetaDataOptionsStoreIDToken     => 1,
                        oidcOPMetaDataOptionsUseNonce         => 0,
                        oidcOPMetaDataOptionsConfigurationURI =>
                          "https://auth.op.com/.well-known/openid-configuration"
                    }
                },
                oidcOPMetaDataJSON => {
                    op => $metadata,
                },
            }
        }
    );
}

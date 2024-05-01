use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use URI::QueryParam;
use Plack::Request;
use Plack::Response;
use JSON;
use URI;
use Crypt::JWT qw(encode_jwt);

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $access_token;

use Lemonldap::NG::Portal::Lib::OpenIDConnect;

my $jwk =
  Lemonldap::NG::Portal::Lib::OpenIDConnect->key2jwks(oidc_key_op_private_sig);

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        note "Internal request to " . $req->path;

        if ( $req->path eq "/oauth2/token" ) {
            is( $req->parameters->{client_id}, "rpid", "expected client_id" );
            is( $req->parameters->{client_secret},
                "rpsecret", "expected client_secret" );
            is(
                $req->parameters->{redirect_uri},
                "http://auth.rp.com/?openidconnectcallback=1",
                "expected redirect_uri"
            );
            is( $req->parameters->{code}, "aaa", "expected code" );

            my $key      = oidc_key_op_private_sig;
            my $response = {
                token_type   => "Bearer",
                access_token => "abc",
                expired_in   => 3600,
                id_token     => encode_jwt(
                    payload => {

                        iss     => "https://op.example.com/",
                        aud     => "rpid",
                        exp     => time + 1000,
                        sub     => "dwho",
                        at_hash => "ungWv48Bz-pBQUDeXa4iIw",
                    },
                    alg           => "RS256",
                    key           => \$key,
                    extra_headers => { kid => "mykid" }
                ),
            };
            return Plack::Response->new( "200",
                { "Content-Type" => "application/json" },
                encode_json($response) )->finalize;
        }

        if ( $req->path eq "/oauth2/jwks" ) {
            $main::jwks_call_count += 1;

            my $kid  = $main::jwks_show_kid ? "mykid" : "wrongkid";
            my $jwks = { keys => [ { kid => $kid, %$jwk } ] };
            return Plack::Response->new( "200",
                { "Content-Type" => "application/json" },
                encode_json($jwks) )->finalize;
        }

        my $res = Plack::Response->new;
        $res->status(500);
        return $res->finalize;
    }
);

my $metadata = <<EOF;
{
  "authorization_endpoint": "https://op.example.com/oauth2/authorize",
  "issuer": "https://op.example.com/",
  "jwks_uri": "https://op.example.com/oauth2/jwks",
  "token_endpoint": "https://op.example.com/oauth2/token",
  "userinfo_endpoint": "https://op.example.com/oauth2/userinfo"
}
EOF

$main::jwks_call_count = 0;
$main::jwks_show_kid   = 0;
my $rp = rp($metadata);
is( $main::jwks_call_count, 1, "JWKS url was called during startup" );

ok( my $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth SP request' );

my ($url) =
  expectRedirection( $res, qr#(https://op.example.com/oauth2/authorize\?.*)# );
$url = URI->new($url);
is( $url->host, "op.example.com", "Correct host" );
my %query = $url->query_form;
is( $query{client_id}, 'rpid',                 "Correct client_id" );
is( $query{scope},     'openid profile email', "Correct scope" );
is(
    $query{redirect_uri},
    'http://auth.rp.com/?openidconnectcallback=1',
    "Correct redirect_uri"
);
ok( my $state = $query{state}, "Found state" );

# Post return authorization code
ok(
    $res = $rp->_get(
        '/',
        query => {
            openidconnectcallback => 1,
            code                  => "aaa",
            state                 => $state,
        },
        accept => 'text/html'
    ),
    'Authorization code'
);
expectPortalError( $res, 106 );

Time::Fake->offset("+600s");
$main::jwks_show_kid = 1;

ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth SP request' );
($url) =
  expectRedirection( $res, qr#(https://op.example.com/oauth2/authorize\?.*)# );
$url = URI->new($url);
is( $url->host, "op.example.com", "Correct host" );
%query = $url->query_form;
is( $query{client_id}, 'rpid',                 "Correct client_id" );
is( $query{scope},     'openid profile email', "Correct scope" );
is(
    $query{redirect_uri},
    'http://auth.rp.com/?openidconnectcallback=1',
    "Correct redirect_uri"
);
ok( $state = $query{state}, "Found state" );

ok(
    $res = $rp->_get(
        '/',
        query => {
            openidconnectcallback => 1,
            code                  => "aaa",
            state                 => $state,
        },
        accept => 'text/html'
    ),
    'Authorization code'
);
is( $main::jwks_call_count, 2, "JWKS url was called again" );
expectCookie($res);

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
                customPlugins => 't::OidcHookPlugin',
            }
        }
    );
}

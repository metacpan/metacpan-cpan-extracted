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
my ( $op, $rp, $res );

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.((?:o|r)p).com(.*)#, ' REST request' );
        my $host = $1;
        my $url  = $2;
        my ( $res, $client );
        count(1);
        if ( $host eq 'op' ) {
            pass("  Request from RP to OP,     endpoint $url");
            $client = $op;
        }
        elsif ( $host eq 'rp' ) {
            pass('  Request from OP to RP');
            $client = $rp;
        }
        else {
            fail('  Aborting REST request (external)');
            return [ 500, [], [] ];
        }
        count(1);
        if ( $req->method =~ /^post$/i ) {
            my $s = $req->content;
            ok(
                $res = $client->_post(
                    $url, IO::String->new($s),
                    length => length($s),
                    type   => $req->header('Content-Type'),
                ),
                '  Execute request'
            );
        }
        else {
            ok(
                $res = $client->_get(
                    $url,
                    (
                        $req->header('Authorization')
                        ? (
                            custom => {
                                HTTP_AUTHORIZATION =>
                                  $req->header('Authorization'),
                            }
                          )
                        : ()
                    ),
                ),
                '  Execute request'
            );
        }
        ok( $res->[0] == 200, '  Response is 200' );
        count(2);
        if ( $url !~ /blogout/ ) {
            ok(
                getHeader( $res, 'Content-Type' ) =~
                  m#^application/(?:json|jwt)#,
                '  Content is JSON'
            ) or explain( $res->[1], 'Content-Type => application/json' );
            count(1);
        }
        return $res;
    }
);

# Initialization
$op = register( 'op', \&op );

ok( $res = $op->_get('/oauth2/jwks'), 'Get JWKS,     endpoint /oauth2/jwks' );
expectOK($res);
my $jwks = $res->[2]->[0];

ok(
    $res = $op->_get('/.well-known/openid-configuration'),
    'Get metadata, endpoint /.well-known/openid-configuration'
);
expectOK($res);
my $metadata = $res->[2]->[0];
count(2);

$rp = register( 'rp', sub { rp( $jwks, $metadata ) } );

# Reload OP so it can fetch RP's JWKS
$op = register( 'op', \&op );

# Verify that RP published its keys
ok( $res = $rp->_get('/oauth2/jwks'), 'RP publish its keys' );
my $rpKeys = expectJSON($res);
my $rpSIgKey;
ok( (
              ref($rpKeys)
          and ref( $rpKeys->{keys} ) eq 'ARRAY'
          and $rpSIgKey = $rpKeys->{keys}->[0]
    ),
    'Get RP sig key'
);
count(2);

# Query RP for auth
ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth RP request' );
count(1);
my ( $url, $query ) =
  expectRedirection( $res, qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

# Push request to OP
ok( $res = $op->_get( $url, query => $query, accept => 'text/html' ),
    "Push request to OP,         endpoint $url" );
count(1);
expectOK($res);

# Try to authenticate to OP
$query = "user=french&password=french&$query";
ok(
    $res = $op->_post(
        $url,
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
    ),
    "Post authentication,        endpoint $url"
);
count(1);
my $idpId = expectCookie($res);
my ( $host, $tmp );
( $host, $tmp, $query ) = expectForm( $res, '#', undef, 'confirm' );

ok(
    $res = $op->_post(
        $url,
        IO::String->new($query),
        accept => 'text/html',
        cookie => "lemonldap=$idpId",
        length => length($query),
    ),
    "Post confirmation,          endpoint $url"
);
count(1);

($query) = expectRedirection( $res, qr#^http://auth.rp.com/?\?(.*)$# );

# Push OP response to RP

ok( $res = $rp->_get( '/', query => $query, accept => 'text/html' ),
    'Call openidconnectcallback on RP' );
count(1);
my $spId = expectCookie($res);

# Logout initiated by OP

# Reset conf to make sure lazy loading works during logout (#3014)
withHandler( 'op', sub { $op->p->HANDLER->checkConf(1) } );

ok(
    $res = $op->_get(
        '/',
        query  => 'logout',
        cookie => "lemonldap=$idpId",
        accept => 'text/html'
    ),
    'Query OP for logout'
);

count(1);
expectOK($res);

# Test if logout is done
ok(
    $res = $op->_get(
        '/', cookie => "lemonldap=$idpId",
    ),
    'Test if user is reject on OP'
);
count(1);
expectReject($res);

ok(
    $res = $rp->_get(
        '/',
        cookie => "lemonldap=$spId",
        accept => 'text/html'
    ),
    'Test if user is reject on RP'
);
count(1);
expectRedirection( $res, qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

clean_sessions();
done_testing( count() );

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'idp.com',
                portal                          => 'http://auth.op.com/',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => "1",
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
                        oidcRPMetaDataOptionsDisplayName           => "RP",
                        oidcRPMetaDataOptionsClientID              => "rpid",
                        oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                        oidcRPMetaDataOptionsIDTokenSignAlg        => "RS256",
                        oidcRPMetaDataOptionsBypassConsent         => 0,
                        oidcRPMetaDataOptionsUserIDAttr            => "",
                        oidcRPMetaDataOptionsUserInfoSignAlg       => 'RS256',
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsLogoutUrl             =>
                          'http://auth.rp.com/oauth2/blogout',
                        oidcRPMetaDataOptionsLogoutType            => 'back',
                        oidcRPMetaDataOptionsLogoutSessionRequired => 1,
                        oidcRPMetaDataOptionsRedirectUris          =>
                          'http://auth.rp.com/?openidconnectcallback=1',
                        oidcRPMetaDataOptionsJwksUri =>
                          'http://auth.rp.com/oauth2/jwks',
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

sub rp {
    my ( $jwks, $metadata ) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $debug,
                domain                     => 'rp.com',
                portal                     => 'http://auth.rp.com/',
                authentication             => 'OpenIDConnect',
                userDB                     => 'Same',
                restSessionServer          => 1,
                oidcOPMetaDataExportedVars => {
                    op => {
                        cn   => "name",
                        uid  => "sub",
                        sn   => "family_name",
                        mail => "email"
                    }
                },
                oidcServiceMetaDataBackChannelURI => 'blogout',
                oidcOPMetaDataOptions             => {
                    op => {
                        oidcOPMetaDataOptionsCheckJWTSignature => 1,
                        oidcOPMetaDataOptionsJWKSTimeout       => 0,
                        oidcOPMetaDataOptionsScope        => "openid profile",
                        oidcOPMetaDataOptionsStoreIDToken => 0,
                        oidcOPMetaDataOptionsDisplay      => "",
                        oidcOPMetaDataOptionsClientID     => "rpid",
                        oidcOPMetaDataOptionsConfigurationURI =>
"https://auth.op.com/.well-known/openid-configuration",
                        oidcOPMetaDataOptionsAuthnEndpointAuthMethod => 'jws',
                        oidcOPMetaDataOptionsTokenEndpointAuthMethod =>
                          'private_key_jwt',
                    }
                },
                oidcServicePrivateKeySig => oidc_key_op_private_sig,
                oidcServicePublicKeySig  => oidc_cert_op_public_sig,
                oidcServiceKeyIdSig      => 'aabbcc',
                oidcOPMetaDataJWKS       => {
                    op => $jwks,
                },
                oidcOPMetaDataJSON => {
                    op => $metadata,
                }
            }
        }
    );
}

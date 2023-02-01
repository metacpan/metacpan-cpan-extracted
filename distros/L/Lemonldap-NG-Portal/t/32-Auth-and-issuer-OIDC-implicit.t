use lib 'inc';
use Test::More;
use strict;
use IO::String;
use JSON;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64 qw/encode_base64 decode_base64 decode_base64url/;

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
                    custom => {
                        HTTP_AUTHORIZATION => $req->header('Authorization'),
                    }
                ),
                '  Execute request'
            );
        }
        ok( $res->[0] == 200, '  Response is 200' );
        ok( getHeader( $res, 'Content-Type' ) =~ m#^application/json#,
            '  Content is JSON' )
          or explain( $res->[1], 'Content-Type => application/json' );
        count(4);
        return $res;
    }
);

# Initialization
ok( $op = op(), 'OP portal' );

ok( $res = $op->_get('/oauth2/jwks'), 'Get JWKS,     endpoint /oauth2/jwks' );
expectOK($res);
my $jwks = $res->[2]->[0];

ok(
    $res = $op->_get('/.well-known/openid-configuration'),
    'Get metadata, endpoint /.well-known/openid-configuration'
);
expectOK($res);
my $metadata = $res->[2]->[0];
count(3);

switch ('rp');
&Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
ok( $rp = rp( $jwks, $metadata ), 'RP portal' );
count(1);

# Query RP for auth
ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth SP request' );
count(1);
my ( $url, $query ) =
  expectRedirection( $res, qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

# Rewrite response_type to use implicit
$query =~ s/response_type=code/response_type=id_token%20token/;

# Push request to OP
switch ('op');
ok( $res = $op->_get( $url, query => $query, accept => 'text/html' ),
    "Push request to OP,         endpoint $url" );
count(1);
expectOK($res);

# Try to authenticate to IdP
$query = "user=dwho&password=dwho&$query&nonce=qwerty";
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

## Consent required
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

($query) = expectRedirection( $res,
    qr#^http://auth.rp.com/?\?openidconnectcallback=1\#(.*)$# );

my %prms = map { split /=/, $_ } split /&/, $query;
ok( $prms{id_token},      ' id_token found' );
ok( $prms{token_type},    ' token_type found' );
ok( $prms{session_state}, ' session_state found' );
ok( $prms{access_token},  ' access_token found' );
ok( $prms{state},         ' state found' );
count(5);

my $id_token_payload = id_token_payload( $prms{id_token} );
is( $id_token_payload->{acr}, "customacr-1", "Check ACR value" );
ok( ( grep { $_ eq "rpid" } @{ $id_token_payload->{aud} } ),
    'Check that clientid is in audience' );
ok( (
        grep { $_ eq "http://my.extra.audience/test" }
          @{ $id_token_payload->{aud} }
    ),
    'Check for additional audiences'
);
ok( ( grep { $_ eq "urn:extra2" } @{ $id_token_payload->{aud} } ),
    'Check for additional audiences' );
count(4);

# Check attributes in ID Token
my $id_token_decoded = id_token_payload( $prms{id_token} );
is( $id_token_decoded->{sub}, "dwho", 'Check sub value' );
ok( !$id_token_decoded->{name}, 'Claim name must not be in ID token' );
is( $id_token_decoded->{azp}, 'rpid', ' azp found' );
count(3);

$op->logout($idpId);

# Query RP for auth
ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth SP request' );
count(1);
( $url, $query ) =
  expectRedirection( $res, qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

# Rewrite response_type to use implicit
$query =~ s/response_type=code/response_type=id_token%20token/;

# Push request to OP
ok( $res = $op->_get( $url, query => $query, accept => 'text/html' ),
    "Push request to OP,         endpoint $url" );
count(1);
expectOK($res);

# Try to authenticate to IdP
$query = "user=dwho&password=dwho&$query&nonce=qwerty";

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
$idpId = expectCookie($res);

# expectRedirection( $res,
#     qr#^http://auth.rp.com/?\?openidconnectcallback=1\#(.*)$# );

# ok(
#     $res = $op->_post(
#         $url,
#         IO::String->new($query),
#         accept => 'text/html',
#         cookie => "lemonldap=$idpId",
#         length => length($query),
#     ),
#     "Post confirmation,          endpoint $url"
# );
#count(1);

#print STDERR Dumper($query);
$op->logout($idpId);
clean_sessions();
done_testing( count() );

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'idp.com',
                portal                          => 'http://auth.op.com',
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
                        oidcRPMetaDataOptionsDisplayName         => "RP",
                        oidcRPMetaDataOptionsAdditionalAudiences =>
                          "http://my.extra.audience/test urn:extra2",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 0,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600
                    }
                },
                oidcOPMetaDataOptions           => {},
                oidcOPMetaDataJSON              => {},
                oidcOPMetaDataJWKS              => {},
                oidcServiceMetaDataAuthnContext => {
                    'loa-4'       => 4,
                    'customacr-1' => 1,
                    'loa-5'       => 5,
                    'loa-2'       => 2,
                    'loa-3'       => 3
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
                portal                     => 'http://auth.rp.com',
                authentication             => 'OpenIDConnect',
                userDB                     => 'Same',
                oidcOPMetaDataExportedVars => {
                    op => {
                        cn   => "name",
                        uid  => "sub",
                        sn   => "family_name",
                        mail => "email"
                    }
                },
                oidcOPMetaDataOptions => {
                    op => {
                        oidcOPMetaDataOptionsCheckJWTSignature => 1,
                        oidcOPMetaDataOptionsJWKSTimeout       => 0,
                        oidcOPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcOPMetaDataOptionsScope        => "openid profile",
                        oidcOPMetaDataOptionsStoreIDToken => 0,
                        oidcOPMetaDataOptionsDisplay      => "",
                        oidcOPMetaDataOptionsClientID     => "rpid",
                        oidcOPMetaDataOptionsConfigurationURI =>
                          "https://auth.op.com/.well-known/openid-configuration"
                    }
                },
                oidcOPMetaDataJWKS => {
                    op => $jwks,
                },
                oidcOPMetaDataJSON => {
                    op => $metadata,
                }
            }
        }
    );
}

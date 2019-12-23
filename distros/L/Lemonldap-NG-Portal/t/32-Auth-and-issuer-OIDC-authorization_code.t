use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
}

my $debug = 'error';
my ( $op, $rp, $res );
my %handlerOR = ( op => [], rp => [] );

my $access_token;

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
        if ( $res->[2]->[0] =~ /"access_token":"(.*?)"/ ) {
            $access_token = $1;
            pass "Found access_token $access_token";
            count(1);
        }
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

# Push request to OP
switch ('op');
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
switch ('rp');

ok( $res = $rp->_get( '/', query => $query, accept => 'text/html' ),
    'Call openidconnectcallback on RP' );
count(1);
my $spId = expectCookie($res);

switch ('op');
ok(
    $res = $op->_get( '/oauth2/checksession.html', accept => 'text.html' ),
    'Check session,      endpoint /oauth2/checksession.html'
);
count(1);
expectOK($res);
ok( getHeader( $res, 'Content-Security-Policy' ) !~ /frame-ancestors/,
    ' Frame can be embedded' )
  or explain( $res->[1],
    'Content-Security-Policy does not contain a frame-ancestors' );
count(1);

# Verify UTF-8
ok(
    $res = $op->_get(
        '/oauth2/userinfo', query => 'access_token=' . $access_token,
    ),
    'Get userinfo'
);
$res = expectJSON($res);
ok( $res->{name} eq 'Frédéric Accents', 'UTF-8 values' )
  or explain( $res, 'name => Frédéric Accents' );
count(2);

ok( $res = $op->_get("/sessions/global/$spId"), 'Get UTF-8' );
$res = expectJSON($res);
ok( $res->{cn} eq 'Frédéric Accents', 'UTF-8 values' )
  or explain( $res, 'cn => Frédéric Accents' );
count(2);

switch ('rp');
ok( $res = $rp->_get("/sessions/global/$spId"), 'Get UTF-8' );
$res = expectJSON($res);
ok( $res->{cn} eq 'Frédéric Accents', 'UTF-8 values' )
  or explain( $res, 'cn => Frédéric Accents' );
count(2);

# Logout initiated by RP
ok(
    $res = $rp->_get(
        '/',
        query  => 'logout',
        cookie => "lemonldap=$spId",
        accept => 'text/html'
    ),
    'Query RP for logout'
);
count(1);
( $url, $query ) = expectRedirection( $res,
    qr#http://auth.op.com(/oauth2/logout)\?(post_logout_redirect_uri=.+)$# );

# Push logout to OP
switch ('op');

ok(
    $res = $op->_get(
        $url,
        query  => $query,
        cookie => "lemonldap=$idpId",
        accept => 'text/html'
    ),
    "Push logout request to OP,     endpoint $url"
);
count(1);

( $host, $tmp, $query ) = expectForm( $res, '#', undef, 'confirm' );

ok(
    $res = $op->_post(
        $url, IO::String->new($query),
        length => length($query),
        cookie => "lemonldap=$idpId",
        accept => 'text/html',
    ),
    "Confirm logout,                endpoint $url"
);
count(1);

( $url, $query ) = expectRedirection( $res, qr#.# );

my $removedCookie = expectCookie($res);
is($removedCookie, 0, "SSO cookie removed");
count(1);

# Test logout endpoint without session
ok(
    $res = $op->_get(
        '/oauth2/logout',
        accept => 'text/html',
        query  => 'post_logout_redirect_uri=http://auth.rp.com/?logout=1'
    ),
    'logout endpoint with redirect, endpoint /oauth2/logout'
);
count(1);
expectRedirection( $res, 'http://auth.rp.com/?logout=1' );

ok( $res = $op->_get('/oauth2/logout'),
    'logout endpoint,               endpoint /oauth2/logout' );
count(1);
expectReject($res);

# Test if logout is done
ok(
    $res = $op->_get(
        '/', cookie => "lemonldap=$idpId",
    ),
    'Test if user is reject on IdP'
);
count(1);
expectReject($res);

switch ('rp');
ok(
    $res = $rp->_get(
        '/',
        accept => 'text/html',
        cookie => "lemonldap=$spId"
    ),
    'Test if user is reject on SP'
);
count(1);
( $url, $query ) =
  expectRedirection( $res, qr#^http://auth.op.com(/oauth2/authorize)\?(.*)$# );

# Test if consent was saved
# -------------------------

# Push request to OP
switch ('op');
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
$idpId = expectCookie($res);

#expectRedirection( $res, qr#^http://auth.rp.com/# );

#print STDERR Dumper($res);

clean_sessions();
done_testing( count() );

sub switch {
    my $type = shift;
    pass( '==> Switching to ' . uc($type) . ' <==' );
    count(1);
    @Lemonldap::NG::Handler::Main::_onReload = @{
        $handlerOR{$type};
    };
}

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'idp.com',
                portal                          => 'http://auth.op.com/',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => "1",
                restSessionServer               => 1,
                oidcRPMetaDataExportedVars      => {
                    rp => {
                        email       => "mail",
                        family_name => "cn",
                        name        => "cn"
                    }
                },
                oidcServiceMetaDataAuthorizeURI       => "authorize",
                oidcServiceMetaDataCheckSessionURI    => "checksession.html",
                oidcServiceMetaDataJWKSURI            => "jwks",
                oidcServiceMetaDataEndSessionURI      => "logout",
                oidcServiceMetaDataRegistrationURI    => "register",
                oidcServiceMetaDataTokenURI           => "token",
                oidcServiceMetaDataUserInfoURI        => "userinfo",
                oidcServiceAllowHybridFlow            => 1,
                oidcServiceAllowImplicitFlow          => 1,
                oidcServiceAllowDynamicRegistration   => 1,
                oidcServiceAllowAuthorizationCodeFlow => 1,
                oidcRPMetaDataOptions                 => {
                    rp => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 0,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsPostLogoutRedirectUris =>
                          "http://auth.rp.com/?logout=1"
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
                oidcServicePrivateKeySig => "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAs2jsmIoFuWzMkilJaA8//5/T30cnuzX9GImXUrFR2k9EKTMt
GMHCdKlWOl3BV+BTAU9TLz7Jzd/iJ5GJ6B8TrH1PHFmHpy8/qE/S5OhinIpIi7eb
ABqnoVcwDdCa8ugzq8k8SWxhRNXfVIlwz4NH1caJ8lmiERFj7IvNKqEhzAk0pyDr
8hubveTC39xREujKlsqutpPAFPJ3f2ybVsdykX5rx0h5SslG3jVWYhZ/SOb2aIzO
r0RMjhQmsYRwbpt3anjlBZ98aOzg7GAkbO8093X5VVk9vaPRg0zxJQ0Do0YLyzkR
isSAIFb0tdKuDnjRGK6y/N2j6At2HjkxntbtGQIDAQABAoIBADYq6LxJd977LWy3
0HT9nboFPIf+SM2qSEc/S5Po+6ipJBA4ZlZCMf7dHa6znet1TDpqA9iQ4YcqIHMH
6xZNQ7hhgSAzG9TrXBHqP+djDlrrGWotvjuy0IfS9ixFnnLWjrtAH9afRWLuG+a/
NHNC1M6DiiTE0TzL/lpt/zzut3CNmWzH+t19X6UsxUg95AzooEeewEYkv25eumWD
mfQZfCtSlIw1sp/QwxeJa/6LJw7KcPZ1wXUm1BN0b9eiKt9Cmni1MS7elgpZlgGt
xtfGTZtNLQ7bgDiM8MHzUfPBhbceNSIx2BeCuOCs/7eaqgpyYHBbAbuBQex2H61l
Lcc3Tz0CgYEA4Kx/avpCPxnvsJ+nHVQm5d/WERuDxk4vH1DNuCYBvXTdVCGADf6a
F5No1JcTH3nPTyPWazOyGdT9LcsEJicLyD8vCM6hBFstG4XjqcAuqG/9DRsElpHQ
yi1zc5DNP7Vxmiz9wII0Mjy0abYKtxnXh9YK4a9g6wrcTpvShhIcIb8CgYEAzGzG
lorVCfX9jXULIznnR/uuP5aSnTEsn0xJeqTlbW0RFWLdj8aIL1peirh1X89HroB9
GeTNqEJXD+3CVL2cx+BRggMDUmEz4hR59meZCDGUyT5fex4LIsceb/ESUl2jo6Sw
HXwWbN67rQ55N4oiOcOppsGxzOHkl5HdExKidycCgYEAr5Qev2tz+fw65LzfzHvH
Kj4S/KuT/5V6He731cFd+sEpdmX3vPgLVAFPG1Q1DZQT/rTzDDQKK0XX1cGiLG63
NnaqOye/jbfzOF8Z277kt51NFMDYhRLPKDD82IOA4xjY/rPKWndmcxwdob8yAIWh
efY76sMz6ntCT+xWSZA9i+ECgYBWMZM2TIlxLsBfEbfFfZewOUWKWEGvd9l5vV/K
D5cRIYivfMUw5yPq2267jPUolayCvniBH4E7beVpuPVUZ7KgcEvNxtlytbt7muil
5Z6X3tf+VodJ0Swe2NhTmNEB26uwxzLe68BE3VFCsbSYn2y48HAq+MawPZr18bHG
ZfgMxwKBgHHRg6HYqF5Pegzk1746uH2G+OoCovk5ylGGYzcH2ghWTK4agCHfBcDt
EYqYAev/l82wi+OZ5O8U+qjFUpT1CVeUJdDs0o5u19v0UJjunU1cwh9jsxBZAWLy
PAGd6SWf4S3uQCTw6dLeMna25YIlPh5qPA6I/pAahe8e3nSu2ckl
-----END RSA PRIVATE KEY-----
",
                oidcServicePublicKeySig => "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAs2jsmIoFuWzMkilJaA8/
/5/T30cnuzX9GImXUrFR2k9EKTMtGMHCdKlWOl3BV+BTAU9TLz7Jzd/iJ5GJ6B8T
rH1PHFmHpy8/qE/S5OhinIpIi7ebABqnoVcwDdCa8ugzq8k8SWxhRNXfVIlwz4NH
1caJ8lmiERFj7IvNKqEhzAk0pyDr8hubveTC39xREujKlsqutpPAFPJ3f2ybVsdy
kX5rx0h5SslG3jVWYhZ/SOb2aIzOr0RMjhQmsYRwbpt3anjlBZ98aOzg7GAkbO80
93X5VVk9vaPRg0zxJQ0Do0YLyzkRisSAIFb0tdKuDnjRGK6y/N2j6At2Hjkxntbt
GQIDAQAB
-----END PUBLIC KEY-----
",
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
                oidcOPMetaDataOptions => {
                    op => {
                        oidcOPMetaDataOptionsCheckJWTSignature => 1,
                        oidcOPMetaDataOptionsJWKSTimeout       => 0,
                        oidcOPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcOPMetaDataOptionsScope        => "openid profile",
                        oidcOPMetaDataOptionsStoreIDToken => 0,
                        oidcOPMetaDataOptionsMaxAge       => 30,
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

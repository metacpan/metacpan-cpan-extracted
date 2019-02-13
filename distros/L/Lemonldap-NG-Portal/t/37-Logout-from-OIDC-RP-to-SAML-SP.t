use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/saml-lib.pm';
}

my $maintests = 25;
my $debug     = 'error';
my ( $op, $rp, $sp, $res );
my %handlerOR = ( op => [], rp => [], sp => [] );

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
            return HTTP::Response->new(500);
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

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found', $maintests;
    }

    # Initialization
    ok( $op = op(), 'OP portal' );
    $handlerOR{op} = \@Lemonldap::NG::Handler::Main::_onReload;

    ok(
        $res = $op->_get('/oauth2/jwks'),
        'Get JWKS,     endpoint /oauth2/jwks'
    );
    expectOK($res);
    my $jwks = $res->[2]->[0];

    ok(
        $res = $op->_get('/.well-known/openid-configuration'),
        'Get metadata, endpoint /.well-known/openid-configuration'
    );
    expectOK($res);
    my $metadata = $res->[2]->[0];

    switch ('sp');
    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    ok( $sp = sp(), 'SP portal' );
    $handlerOR{sp} = \@Lemonldap::NG::Handler::Main::_onReload;

    switch ('rp');
    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    ok( $rp = rp( $jwks, $metadata ), 'RP portal' );
    $handlerOR{rp} = \@Lemonldap::NG::Handler::Main::_onReload;

    # Query RP for auth
    ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth SP request' );
    my ( $url, $query ) =
      expectRedirection( $res,
        qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

    # Push request to OP
    switch ('op');
    ok( $res = $op->_get( $url, query => $query, accept => 'text/html' ),
        "Push request to OP,         endpoint $url" );
    expectOK($res);
    my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Try to authenticate to IdP
    $query = "user=french&password=french&$query";
    ok(
        $res = $op->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => $pdata,
        ),
        "Post authentication,        endpoint $url"
    );
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

    ($query) = expectRedirection( $res, qr#^http://auth.rp.com/?\?(.*)$# );

    # Push OP response to RP
    switch ('rp');

    ok( $res = $rp->_get( '/', query => $query, accept => 'text/html' ),
        'Call openidconnectcallback on RP' );
    my $rpId = expectCookie($res);

    switch ('op');
    ok(
        $res = $op->_get( '/oauth2/checksession.html', accept => 'text.html' ),
        'Check session,      endpoint /oauth2/checksession.html'
    );
    expectOK($res);
    ok( getHeader( $res, 'Content-Security-Policy' ) !~ /frame-ancestors/,
        ' Frame can be embedded' )
      or explain( $res->[1],
        'Content-Security-Policy does not contain a frame-ancestors' );

    # SAML
    switch ('sp');
    ok(
        $res = $sp->_get(
            '/',
            accept => 'text/html',
            cookie => 'lemonldapidp=http://auth.op.com/saml/metadata'
        ),
        'Try SAML SP'
    );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.op.com', '/saml/singleSignOn',
        'SAMLRequest' );

    switch ('op');
    ok(
        $res = $op->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => "lemonldap=$idpId",
        ),
        'Post SAML request to IdP'
    );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    # Post SAML response to SP
    switch ('sp');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => 'lemonldapidp=http://auth.idp.com/saml/metadata',
        ),
        'Post SAML response to SP'
    );
    my $spId = expectCookie($res);

    # Logout initiated by RP
    switch ('rp');
    ok(
        $res = $rp->_get(
            '/',
            query  => 'logout',
            cookie => "lemonldap=$rpId",
            accept => 'text/html'
        ),
        'Query SP for logout'
    );
    ( $url, $query ) = expectRedirection( $res,
        qr#http://auth.op.com(/oauth2/logout)\?(post_logout_redirect_uri=.+)$#
    );

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
    expectOK($res);

    ok(
        $res->[2]->[0] =~
m#iframe src="http://auth.op.com(/saml/relaySingleLogoutPOST)\?(relay=.*?)"#s,
        'Get iframe request'
    ) or explain( $res, '' );
    ( $url, $query ) = ( $1, $2 );
    switch ('op');
    ok(
        $res = $op->_get(
            $url,
            query  => $query,
            cookie => "lemonldap=$idpId",
            accept => 'text/html'
        ),
        'Get iframe'
    );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleLogout',
        'SAMLRequest' );

    # Post SAML logout request to SP
    switch ('sp');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => "lemonldap=$spId",
        ),
        'Post SAML logout request to SP'
    );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.op.com', '/saml/singleLogoutReturn',
        'SAMLResponse' );

    # Post SAML logout response to IdP
    switch ('op');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => "lemonldap=$spId",
        ),
        'Post SAML logout response to IdP'
    );

    # Test if logout is done
    ok(
        $res = $op->_get(
            '/', cookie => "lemonldap=$idpId",
        ),
        'Test if user is reject on IdP'
    );
    expectReject($res);

    switch ('rp');
    ok(
        $res = $rp->_get(
            '/',
            accept => 'text/html',
            cookie =>
              "lemonldapidp=http://auth.op.com/saml/metadata; lemonldap=$rpId"
        ),
        'Test if user is reject on SP'
    );
    expectRedirection( $res, qr#^http://auth.op.com/oauth2/authorize# );

    switch ('sp');
    ok(
        $res = $sp->_get(
            '/',
            accept => 'text/html',
            cookie =>
              "lemonldapidp=http://auth.op.com/saml/metadata; lemonldap=$spId"
        ),
        'Test if user is reject on SP'
    );
    expectOK($res);
    expectAutoPost( $res, 'auth.op.com', '/saml/singleSignOn', 'SAMLRequest' );
}

count($maintests);
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
                domain                          => 'op.com',
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
                oidcServiceMetaDataIssuer             => "http://auth.op.com",
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
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600
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
                issuerDBSAMLActivation => 1,
                samlSPMetaDataOptions  => {
                    'sp.com' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                    }
                },
                samlSPMetaDataExportedAttributes => {
                    'sp.com' => {
                        cn =>
'1;cn;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                        uid =>
'1;uid;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                    }
                },
                samlOrganizationDisplayName => "IDP",
                samlOrganizationName        => "IDP",
                samlOrganizationURL         => "http://www.op.com/",
                samlServicePrivateKeyEnc    => "-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAnfKBDG/K0TnGT7Xu8q1N45sNWvIK91SqNg8nvN2uVeKoHADT
csus5Xn3id5+8Q9TuMFsW9kIEeXiaPKXQa9ryfSNDhWDWloNkpGEeWif2BnHUu46
Abu1UBWb0mH6VwcG1PR4qHruLis1odjQ1qnVDNfSEASVIppEBYjDX203ypmURIzU
6h53GRRRlf1BLWkbVn9ysmDeR57Xw5Rsx/+tBlcnMrkv/40DSUkehQIl2JmlFrl2
Caik+gU4pd20apA/pNLjBZF0OmGoS08AIR5NMd0KFa6CwZUUSHJqH5GFy5Y2yl4l
g8K0klAS9q7L7aXI+eFQZhkwidjpxXnHPyxIGQIDAQABAoIBAHnfqjX3eO8SfnP5
NURp90Td2mNHirCn0qLd9NKl1ySMPR1GgeH9SQ7Umu32EcteAUL5dOw2PiTZVmeW
cKINgsWVftXUQcOQ4xIqWKb51QUBdy0FhxrZRSFjWxXt5iYK1PmzHfsax/g1/S9C
RnqtFyjOy1bywkSt9jiy+9YBR2B7BDhLHlILbijWn5zaecaV4YA+L1UK4M/mehdb
+0FVPavbGpnlqBRTY+7YXfZ/mRPCfn5DvO9lW1O0pJMmNdBh9kmm3DxHf6AkK47a
43gO/dRWiWo2rZ/+Jw7uyqOb23U0MydP7kia0p3tzCUBPsrlgnichYG5RNFp0wqy
3VT1TYECgYEA0Y9vENy1jJd+s7WbGrsRtSKxfZgtJr0yjSlQVYrIlwbZSGn+ndxq
V2vVlwIgLX3pz6T40BMfk6SNx08jjy0Sgn6OAM0ILrinno8yWcSAMCmfCU0S/3O1
55bqtcnk4XTHBHzJ5OrnrPaW5ourvJz0lcWEKMg3BXxLzaF6ZRy85nECgYEAwPMD
LNAKLCDrUMyYFOpPyPLe7wvszcFvPipGgerSgFP1c6N7xaMUdHDYqBfuis1khPGF
YcMHeNBYmzX6yEGbp3lrB4PHpUySmTU3mv3u9I05aahInK21gXum3uRkCWyyIF6V
T/qeszl9mVOCp0CC4eG3IMVpaD0UKDEHVhERYCkCgYAjuTPRyA4a3Wh38ilysRkf
q75eDqcDx5Tqg3RyYKo5NK2troP9HSnzpSpQB8i8eI53G0RfFCN5479XjqIdMi3J
mRFUCZ+vd0L7wKVwsBK6Ix49U6o9adhElnGEc9pUpLeYiD1SjMjZr1+iBYVNLeRz
86vH1/mpMbsqXrCis/dvwQKBgGttomHr/w3s0jftget7PirrFrbP0+wHfDGHhjRF
kyhCFtJovrwefYALaIXGtVjw3LusYZA570oT7pGUb2naJZkMYEwR0jG1vZWx7KDO
K6JbkxDB0pPxn7JVL2bAkPYyX8boAohCSOQO6WBZ/8+xem3bp4OGhpa0EyoBik0g
OaVpAoGATj4SyYsE10hGT676iie8zy3fi5IPC3E+x4QlVuusaLtuY8LJA50stjtx
gUa/JAKlZZL+gvzvOviQIxyfIChXOdTt5uiOYkdHJDbAF3NSrji7hrXq4v8UZv75
8hBrwJZIpy6y01dRlrriHmPRtEq1pk7JX2uUg0sP5g4BEcsaCbc=
-----END RSA PRIVATE KEY-----
",
                samlServicePrivateKeySig => "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAtR/wgDqWB4Maho5V6TjcL/NbNfjgIh7GcgkrB5RZcVT1GTej
JlMjUQdgBKBuZXQN+7/29P6UcGq1kYalURq6S8SpeJ1ofp5rBEoD/TIkvU0JOcid
65wp+fdzXGXsfiZvHraU74jSCgjP/wqfVGRyBIQzB0SIxSpnrsigqNsE1E94toDM
x4wovjHu/9ABAImREV7Sz83OeFF00/sghrjTEJOD/gHf04JCn9MgNOqvSTysr9LX
Wg/oUKQDEYeTq9ux6pq/oqv1MxwONbSZPtN5yD41mi+hT8Rh+W8Je8rsiML4VMxz
sb1l9303asw6suo5bLTISKNSbu1nt1NkpNxzywIDAQABAoIBAQCQkbvPPfP+bwC/
IeEk1IO7qkzFWa7czR+safD0jc6OjTdNN4F716Q6yt4zEzLKu8VliiW+C23EBQiD
7asKf4DvdTun0ExVtHDK7aEdeealSlXwz1ZtdypyILbtq1UGo/rR0v4x601rQPl0
IrBmFf6D6FkqleNtLJmxguXpoVfLdYKNwkxH2ux+GOA9r2o5pUCQmJGDap5YWRuQ
uB71ewJjVWujaL3e1ac/5cP7/tqWmgAiOaN8sYdD6+oWOR47bHj8JKcMBSl4y2QC
dL31cGmmf5KqBbtISki3RXfHHjT7E3Z85CbESkKTZlEb1ar3XmepY6Z7V5UO16oz
fFE5R6khAoGBAOl9Qb+qYVVO5ugE65ORjYVeuXykANhM9ssiY5a6zuAakWzw7Zv3
k6PXm9p7azlEXAlTnTXVwHYMyuuzZDvQ8LRV1iBOdPuIkUAmaQ5K9ASD7VcoHexh
k8DAKf9Ln7sTRaMdvgceRNczOmJOBIEpTZkssA/jVGXZsoyTWYl1en/ZAoGBAMaW
RnNbSNprEV2b8UeAJ6i77c4SXwu1I8X2NLtiLScb1ETBjfrdHmdlJglfyd/0gmhH
p/43Ku2iGUoY5KtuOI6QmahrJYQscRQhoj252VXadG6fNWWAlpgdCm9houhHb5BF
3zge/bTr0anUe9EA7Z/ymav12rEouoNjIlhI9C5DAoGATR85a2SMt8/TB0owwdJu
62GpZNkLCmcJkXkvaecUVAOSi2hdI4o4MwMRkK35cbX5rH74y4JqCtQY5pefgP53
sykzDAK+MyMdzxGg2764MRGegI5Yq+5jDmSquo+xF+q6srEtRk6iMG7UVwosBLmu
zuxqzySoiOfKSRKWnYe3SakCgYEAwWMkVkAmETXE4oDzFSsS8/mW2l//mPocTTK3
JWe1CunJ6+8FYbAlZJEW2ngismp8+CoXybNVpbZ+pC7buKoMf6EHUgCNt0pEEFO0
mCG9KSMk0XlPWXpArP9S4yaUq1itpzSz7QYZES+4rIcU0HLz9RgeWFyCTJWaFErc
7laVG9sCgYBKOtk5WlIOP4BxSd2y4cYzohgwTZIs1/2kTEn1u4eH73M1xvAlHHFB
wSF5QXgDKJ8pPAOhNWpdLO/PdtnQn91nOvTNc+ShJZzjdbneUdQVpWpoBf72uA+N
6rIVf1JBUL2p7HFHaGdUZC7KGQ+yv6ZHrE1+7202nuDvJdvGEEdFsQ==
-----END RSA PRIVATE KEY-----
",
                samlServicePublicKeyEnc => "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnfKBDG/K0TnGT7Xu8q1N
45sNWvIK91SqNg8nvN2uVeKoHADTcsus5Xn3id5+8Q9TuMFsW9kIEeXiaPKXQa9r
yfSNDhWDWloNkpGEeWif2BnHUu46Abu1UBWb0mH6VwcG1PR4qHruLis1odjQ1qnV
DNfSEASVIppEBYjDX203ypmURIzU6h53GRRRlf1BLWkbVn9ysmDeR57Xw5Rsx/+t
BlcnMrkv/40DSUkehQIl2JmlFrl2Caik+gU4pd20apA/pNLjBZF0OmGoS08AIR5N
Md0KFa6CwZUUSHJqH5GFy5Y2yl4lg8K0klAS9q7L7aXI+eFQZhkwidjpxXnHPyxI
GQIDAQAB
-----END PUBLIC KEY-----
",
                samlServicePublicKeySig => "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtR/wgDqWB4Maho5V6Tjc
L/NbNfjgIh7GcgkrB5RZcVT1GTejJlMjUQdgBKBuZXQN+7/29P6UcGq1kYalURq6
S8SpeJ1ofp5rBEoD/TIkvU0JOcid65wp+fdzXGXsfiZvHraU74jSCgjP/wqfVGRy
BIQzB0SIxSpnrsigqNsE1E94toDMx4wovjHu/9ABAImREV7Sz83OeFF00/sghrjT
EJOD/gHf04JCn9MgNOqvSTysr9LXWg/oUKQDEYeTq9ux6pq/oqv1MxwONbSZPtN5
yD41mi+hT8Rh+W8Je8rsiML4VMxzsb1l9303asw6suo5bLTISKNSbu1nt1NkpNxz
ywIDAQAB
-----END PUBLIC KEY-----
",
                samlSPMetaDataXML => {
                    "sp.com" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'sp', 'HTTP-POST' )
                    },
                }
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
                        oidcOPMetaDataOptionsJWKSTimeout  => 0,
                        oidcOPMetaDataOptionsClientSecret => "rpsecret",
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

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                          => $debug,
                domain                            => 'sp.com',
                portal                            => 'http://auth.sp.com',
                authentication                    => 'SAML',
                userDB                            => 'Same',
                issuerDBSAMLActivation            => 0,
                restSessionServer                 => 1,
                samlIDPMetaDataExportedAttributes => {
                    idp => {
                        mail => "0;mail;;",
                        uid  => "1;uid",
                        cn   => "0;cn"
                    }
                },
                samlIDPMetaDataOptions => {
                    idp => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'post',
                        samlIDPMetaDataOptionsSLOBinding     => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 1,
                    }
                },
                samlIDPMetaDataExportedAttributes => {
                    idp => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                },
                samlIDPMetaDataXML => {
                    idp => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'op', 'HTTP-POST' )
                    }
                },
                samlOrganizationDisplayName => "SP",
                samlOrganizationName        => "SP",
                samlOrganizationURL         => "http://www.sp.com",
                samlServicePublicKeySig     => "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAu4iToYAEmWQxgZDihGVz
MMql1elPn37domWcvXeU2E4yt2hh5jkQHiFjgodfOlNeRIw5QJVlUBwr+CQvbaKR
FXd7BrOhQIDC0TZPRVB0XHarUtsCuDekN4/2GKSzHsoToKUVPWq9thsuek3xkpsJ
GZNX7bglfEc9+QQpYTqN1rkdN1PVU0epNMokFFGho5pLRqLUV5+I/QXAL49jfTja
Sxsp4UndTI8/+mGSRSq+nrT2zyQRM/vkj5vR9ZVz67HO/+Wk3Mx6RAwkVcMdgMAq
Cq8odmbI0yCRZiTL9ybKWRKqWJoKJ0p5+Q2fPEBPupQZR09Jt/JPuLVSsGfCxi9N
qwIDAQAB
-----END PUBLIC KEY-----
",
                samlServicePrivateKeyEnc => "-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAsRaod2RZ8hMFBl+VhsnhyPM8l/Fj1obnBxfQIaWuHFIFfXiG
e/CYHuZ5QJQLnZxHMJX6LL3Sh+Usog3p0jpijpcg0QgfBSEkfopKTgReYN8DiDIl
l0rV1XdTni7E85Nd1YyNy3ui/ZD+UShWwqu6jLVLR+QUm+/1LIKYb3OCBTvOlY7x
HoP6NSU1+Mr+YzGBUacdO2vnNxe/PQhxIeP1zO0njuqGHkwEpy8rUWRZbbDn31Tm
Kjqlhgtsz5HPhbRaYEExhyepKgBiNz+RyxtYXVhuG8OrWQDoS5gYHSjdw1CTJyix
eJwyoqA9RGYguG5nh9zndi3LWAh7Z0lx+tIz+wIDAQABAoIBAEkZrk8iiJKJ0WAx
IrsyKNbXuWKLTYgnxcRCyzKofrfID+YcU39j8JeI0fKbajQUZ7qhnlTLwtU//+2h
SqzyVu6/add/v7ZRWQw3L7cGzKK2THHzKVtLk/t7N3QroDdf1LMrQvkFP2HmcWS0
/yN62hXtXHb/qpY4Nn+6JQyUpM5dkv8S/QjDl2NTdyWrXKzWp+4I3QLQ20f4zym+
ir7RennziMc0HlQNcTjGAUbFULtdqEfSFWhNK7UjiRY+S0XV2xJIbGjnxUQH62fS
w1ZzYsF7sBtoSckvfL4WfGbylhOVnliU05RLU2c67PRjj1Gskoslq1Ow/3DHR7rI
BSBpV8ECgYEA1eHfcog7xQGDkW+cshJtFPFx+9MegB58gFW1rl0rn+tfbexvoSEA
7G7EOTyaU6OAI+8StiRT6AYTgEU7PMM9zDykdGIWj3h0OpHGA86xhEiiaaM2DDRv
/DEKRVlEdmRLLLY28pJVHOMYomia3mb2VKZGg2VfGtSfjg1GXD3I8OECgYEA0/X0
U55KjZ1JQTPUgFc1WK1NxX9MaH+NcpDaolEUy3Qf3QTbfws+a9K3vwCn7EpQhrfs
I6RVUtwFdCyfl/jzBY9Gykkg03sMgW7Qw2SCCsSt05M+jDtBbNJ7esP6PAeKFvXZ
ZWhdeiAa4kM/P6gtvZXQ4tY4LkSbcd6b0SzzFFsCgYBjMsusFzuBd95JyfZnMNye
5gzzu0teKMWd0CLfqB7foQ81sH9lwCTpg8ZGtbDuMdrwz6ViDR9NceQBjhqXaAZ1
f3rW79d+22Ms9wdcJLV4oSeSzzv2FSwLT8NvvqNeNc4YArshbnVDXKDEUrfhhueh
Ay2ZK58clpkaDVYg2hckgQKBgG3KuhtSI/YE4fwXN9yez7A2XNGPZem/IGqWo9lu
PGJCrXqT2IqPLW82gB083r6jo+CUhonTxqqb82tA7g4PUvqvQ5Dmnk1NMKYe255K
gp3HUO8GF2EWFIak5Hcr6oOLuDi6cjh3/euTk7ld8fYsTD0mzEOjiQhWW1p5X6bT
LLp/AoGAHvkxA1NM1HJ3myAREbwNXxRy/nhNt4mwMkZ6hPQsW/Eg/3r7j6MJOFrm
U8AJJjDGKe6nlXhhnMoQfJzAc0cYNgjktmJXW27fHGIwt/2QwYNFHPK3s7HTrfH6
7T4XKT3yGeeeyC2soKJQPlGB+ETdIUnXa7eo9KVWtMTgISyx1Qk=
-----END RSA PRIVATE KEY-----
",
                samlServicePrivateKeySig => "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAu4iToYAEmWQxgZDihGVzMMql1elPn37domWcvXeU2E4yt2hh
5jkQHiFjgodfOlNeRIw5QJVlUBwr+CQvbaKRFXd7BrOhQIDC0TZPRVB0XHarUtsC
uDekN4/2GKSzHsoToKUVPWq9thsuek3xkpsJGZNX7bglfEc9+QQpYTqN1rkdN1PV
U0epNMokFFGho5pLRqLUV5+I/QXAL49jfTjaSxsp4UndTI8/+mGSRSq+nrT2zyQR
M/vkj5vR9ZVz67HO/+Wk3Mx6RAwkVcMdgMAqCq8odmbI0yCRZiTL9ybKWRKqWJoK
J0p5+Q2fPEBPupQZR09Jt/JPuLVSsGfCxi9NqwIDAQABAoIBABE0Cjb6g3F+23vD
SsRSeiqzrFrfOEqtXK+VGrfWzHS7V7Ozg6eW/H+HGJXUzUuQcklfg7EFA3JB41a0
GxW3oA+UElkfCV/dcAG5NbRqGQKScEz9glZb5FikgDLqiPP+HabS/gvQSu71t2HI
3KxSRJdwCNTp26Z28pxxYUpmELTtxd9vlHjffit2Mnt2uc8hOtFHdNavfYwvYH7o
bmlckp7b/JVOy2Yy21O94ZWkE498jXyn71Gr+V1cnJ0RrmYbhQqIvFpFHj98Pf4O
if3c4YmBcZ4t7PUsZUYF3ooWt8k/mdigQC3D6p80OKe+wUTYKcCN0ZdFbiURv9pg
CsqLh+ECgYEA9vA+9QfzvXC7S5yXgTkuRiusPlNye/AiyA/0oGjmjFZ1YNsT7awH
6BjW6WE+rS4elKJu1GaefM/cDguH4ZmJc+eKgi4LDCqYw9rr9les3aneBc8demd3
O/Ej1Pud1QxXArBNfBYo08vEqwST9P89clJC5090U6bGK2E0rTVu1w0CgYEAwmpG
9LbOFeGCPmwX7Avuk7tQQfRSV6q9TFZo+HxDfKYvxec846l1vBenY2rrgYhtolYJ
YS795LYgbSWRxGfgr1GuIbP5GsjHy6/1o6bS8M++GJ7KHArb0QLAYyQweqqb164A
NvHJkveueWnxzeOlD9j2fcjEnBHwTnqjG+17CZcCgYEAqMXawa4FsNxzpmIISpHC
RsNindZ60Kp3mzUMhPYtXI1a/C+/lxmU7dTMTgXgyIxU6lF6XkEk4TlPtWm8HTzK
7SS7Te4aLt6OOo5N57hUtct7q4y7IQXGQHm3e8HdRdeBQJ0u2Dhs/xSt/hTK6w/n
91Kx11Y+s02w88UkM53pe6ECgYAF/UYwVc1liSv9BlF6WSfBb1zam09KGh1405Sq
SxG9LlV8cFJE5TyWTdg/TNTyiaRvAt2JG+yAdkfrdOPXvCeE3yxRJ30+IP9evA4C
O6p19sBxe7rYQFFjUAVjSIMh1E22yEqDZtGB8JV0chob8K5uHY4CdAPylu7jTA3o
V1maAwKBgQCSGQ3yzsk4EGN2xd/JdgGDzhKyTZTQKMWYqQcsYxRAQ7Paj7u+Wkgv
dBeKcI0HwgpLy5ZohSd2erqieIsW0pEbJWCmos4IcO8tgNfEOa5WXYdyLbj5tFwt
ctu4/BJdijqfpMAtG8pv6k09gYjfASVytXmydGcs/0rVKYCRQA8Tow==
-----END RSA PRIVATE KEY-----
",
                samlServicePublicKeyEnc => "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsRaod2RZ8hMFBl+Vhsnh
yPM8l/Fj1obnBxfQIaWuHFIFfXiGe/CYHuZ5QJQLnZxHMJX6LL3Sh+Usog3p0jpi
jpcg0QgfBSEkfopKTgReYN8DiDIll0rV1XdTni7E85Nd1YyNy3ui/ZD+UShWwqu6
jLVLR+QUm+/1LIKYb3OCBTvOlY7xHoP6NSU1+Mr+YzGBUacdO2vnNxe/PQhxIeP1
zO0njuqGHkwEpy8rUWRZbbDn31TmKjqlhgtsz5HPhbRaYEExhyepKgBiNz+RyxtY
XVhuG8OrWQDoS5gYHSjdw1CTJyixeJwyoqA9RGYguG5nh9zndi3LWAh7Z0lx+tIz
+wIDAQAB
-----END PUBLIC KEY-----
",
                samlSPSSODescriptorAuthnRequestsSigned => 1,
            },
        }
    );
}

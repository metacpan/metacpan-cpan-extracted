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
my $access_token;
my $op;
my $res;

# Initialization
ok( $op = op(), 'OP portal' );
count(1);

# Request for RP1
my $authrequest1 = buildForm( {
        scope         => "openid",
        response_type => "code",
        client_id     => "rpid",
        redirect_uri  => "http://rp1.example.com/",
    }
);
ok(
    $res = $op->_get(
        '/oauth2/authorize',
        accept => 'text/html',
        query  => $authrequest1
    ),
    'Authorization request to RP1'
);
count(1);

my $pdata = expectCookie( $res, 'lemonldappdata' );

# Uncomment this to make the unit test pass
#my $pdata = "";

# Uncomment this to wait until issuersTimeout has expired, leading to a different error
Time::Fake->offset("+10m");

# Request for RP2 with previous pdata still around
my $authrequest2 = buildForm( {
        scope         => "openid",
        response_type => "code",
        client_id     => "rp2id",
        redirect_uri  => "http://rp2.example.com/",
    }
);
ok(
    $res = $op->_get(
        '/oauth2/authorize',
        accept => 'text/html',
        query  => $authrequest2,
        cookie => "lemonldappdata=$pdata",

    ),
    'Authorization request to RP2'
);
count(1);

$pdata = expectCookie( $res, 'lemonldappdata' );
my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'user', 'password' );

$query =~ s/user=/user=dwho/;
$query =~ s/password=/password=dwho/;

# Login to OP
ok(
    $res = $op->_post(
        '/oauth2/authorize',
        IO::String->new($query),
        query  => $authrequest2,
        accept => 'text/html',
        length => length($query),
        cookie => "lemonldappdata=$pdata",

    ),
    'Authorization request to RP2'
);
count(1);

$pdata = expectCookie( $res, 'lemonldappdata' );

# Process second factor
( $host, $url, $query ) =
  expectForm( $res, undef, '/ext2fcheck?skin=bootstrap', 'token', 'code' );

ok(
    $res->[2]->[0] =~
qr%<input name="code" value="" type="text" class="form-control" id="extcode" trplaceholder="code" autocomplete="one-time-code" />%,
    'Found EXTCODE input'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

$query =~ s/code=/code=A1b2C0/;
ok(
    $res = $op->_post(
        '/ext2fcheck',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
        cookie => "lemonldappdata=$pdata",

    ),
    'Post code'
);
count(1);

# We now should be logged in, but lost the original URL
expectRedirection( $res, "http://auth.op.com/oauth2" );
my $id = expectCookie($res);

ok(
    $res = $op->_get(
        '/oauth2',
        accept => 'text/html',
        cookie => "lemonldap=$id; lemonldappdata=$pdata",
    ),
    'Authorization request to RP1'
);
count(1);

# We should be redirected to RP2
expectRedirection( $res, qr#^http://rp2.example.com/# );

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
                ext2fActivation                 => 1,
                ext2fCodeActivation             => 'A1b2C0',
                ext2FSendCommand                => '/bin/true',
                issuerDBOpenIDConnectActivation => "1",
                restSessionServer               => 1,
                oidcRPMetaDataExportedVars      => {
                    rp => {
                        email       => "mail",
                        family_name => "cn",
                        name        => "cn"
                    },
                    rp2 => {
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
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 0,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration  => 3600,
                        oidcRPMetaDataOptionsBypassConsent          => 1,
                        oidcRPMetaDataOptionsPostLogoutRedirectUris =>
                          "http://auth.rp.com/?logout=1"
                    },
                    rp2 => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rp2id",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 0,
                        oidcRPMetaDataOptionsClientSecret      => "rp2secret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration  => 3600,
                        oidcRPMetaDataOptionsBypassConsent          => 1,
                        oidcRPMetaDataOptionsPostLogoutRedirectUris =>
                          "http://auth.rp2.com/?logout=1"
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


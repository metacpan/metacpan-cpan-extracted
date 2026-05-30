use warnings;
use Test::More;
use strict;
use IO::String;
use JSON;
use LWP::UserAgent;
use LWP::Protocol::PSGI;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $debug = 'error';
my ( $op, $rp, $res );
my @bclReceived = ();

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
            if ( $url =~ /blogout/ ) {
                push @bclReceived, { url => $url, content => $req->content };
            }
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
        count(3);
        return $res;
    }
);

# Initialization
ok( $op = register( 'op', sub { op() } ), 'OP portal' );

ok( $res = $op->_get('/oauth2/jwks'), 'Get JWKS' );
expectOK($res);
my $jwks = $res->[2]->[0];

ok( $res = $op->_get('/.well-known/openid-configuration'), 'Get metadata' );
expectOK($res);
my $metadata = $res->[2]->[0];
count(3);

&Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
ok( $rp = register( 'rp', sub { rp( $jwks, $metadata ) } ), 'RP portal' );
count(1);

# Create sessions
ok(
    $res = $op->_post(
        '/',
        IO::String->new('user=french&password=french'),
        length => 27,
        accept => 'text/html',
    ),
    'First OP authentication'
);
count(1);
my $idpId1 = expectCookie($res);
expectRedirection( $res, 'http://auth.op.com/' );

ok(
    $res = $op->_post(
        '/',
        IO::String->new('user=french&password=french'),
        length => 27,
        accept => 'text/html',
    ),
    'Second OP authentication'
);
count(1);
my $idpId2 = expectCookie($res);
expectRedirection( $res, 'http://auth.op.com/' );

my $nbr = count_sessions();
ok( $nbr == 2, "Two SSO sessions found" )
  or explain("Number of session(s) found = $nbr");
count(1);

ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth RP request' );
count(1);
my ( $url, $query ) =
  expectRedirection( $res, qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

ok(
    $res = $op->_get(
        $url,
        query  => $query,
        cookie => "lemonldap=$idpId1",
        accept => 'text/html'
    ),
    "Push request to OP"
);
count(1);

my ( $host, $tmp );
( $host, $tmp, $query ) = expectForm( $res, '#', undef, 'confirm' );

ok(
    $res = $op->_post(
        $url,
        IO::String->new($query),
        accept => 'text/html',
        cookie => "lemonldap=$idpId1",
        length => length($query),
    ),
    "Post confirmation"
);
count(1);

($query) = expectRedirection( $res, qr#^http://auth.rp.com/?\?(.*)$# );

ok( $res = $rp->_get( '/', query => $query, accept => 'text/html' ),
    'Complete OIDC callback on RP' );
count(1);
my $rpId = expectCookie($res);

ok( $res = $rp->_get( '/', cookie => "lemonldap=$rpId" ),
    'Verify RP session is valid' );
count(1);
expectOK($res);

# Call globalLogout
@bclReceived = ();
ok(
    $res = $op->_get(
        '/',
        query  => 'logout',
        cookie => "lemonldap=$idpId2",
        accept => 'text/html'
    ),
    'Session 2 initiates logout with GlobalLogout'
);
count(1);

my $formQuery;
( $host, $url, $formQuery ) =
  expectForm( $res, undef, '/globallogout?all=1', 'token' );
ok( $res->[2]->[0] =~ m%<span trspan="globalLogout">%,
    'Found GlobalLogout form' );
count(1);

$formQuery .= '&all=1';
ok(
    $res = $op->_post(
        '/globallogout',
        IO::String->new($formQuery),
        cookie => "lemonldap=$idpId2",
        length => length($formQuery),
        accept => 'text/html',
    ),
    'Confirm GlobalLogout'
);
count(1);
ok( $res->[2]->[0] =~ m%<span trmsg="47"></span>%, 'Found PE_LOGOUT_OK' );
count(1);

ok( scalar(@bclReceived) >= 1, 'At least one BCL request sent to RP' )
  or explain( \@bclReceived, 'Expected BCL requests' );
count(1);

ok(
    $res = $rp->_get(
        '/',
        cookie => "lemonldap=$rpId",
        accept => 'text/html'
    ),
    'Check RP session after GlobalLogout BCL'
);
count(1);
expectRedirection( $res, qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

$nbr = count_sessions();
ok( $nbr == 0, "No SSO sessions remaining" )
  or explain("Number of session(s) found = $nbr");
count(1);

clean_sessions();
done_testing( count() );

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'op.com',
                portal                          => 'http://auth.op.com/',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => 1,
                globalLogoutRule                => 1,
                globalLogoutTimer               => 10,
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
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 0,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsLogoutUrl             =>
                          'http://auth.rp.com/oauth2/blogout',
                        oidcRPMetaDataOptionsLogoutType            => 'back',
                        oidcRPMetaDataOptionsLogoutSessionRequired => 1,
                        oidcRPMetaDataOptionsRedirectUris          =>
                          'http://auth.rp.com/?openidconnectcallback=1',
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

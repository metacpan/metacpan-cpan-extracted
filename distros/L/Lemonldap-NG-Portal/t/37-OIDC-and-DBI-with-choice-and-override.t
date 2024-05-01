use warnings;
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

my ( $op, $rp, $res );

my $userdb = tempdb();

no warnings 'once';

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

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', 1;
        count(1);
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");

    # login    : dr.who
    # mobile_id: dwho (value returned by OIDC/Demo
    $dbh->do('CREATE TABLE users (login text,password text,mobile_id text)');
    $dbh->do("INSERT INTO users VALUES ('dr.who','dwho','dwho')");

    ok( $op = register( 'op', sub { op() } ), 'OP portal' );
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
    count(3);

    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    ok( $rp = register( 'rp', sub { rp( $jwks, $metadata ) } ), 'RP portal' );
    count(1);

    # Reload OP so it can fetch RP's JWKS
    withHandler( 'op', sub { $op->p->HANDLER->checkConf(1) } );

    my $query = 'user=dr%2Ewho&password=dwho&test=sql';
    ok(
        $res = $rp->_post(
            '/', IO::String->new($query),
            length => length($query),

            #accept => 'text/html',
        ),
        'Auth query'
    );
    count(1);
    my $id = expectCookie($res);
    $rp->logout($id);

    # Test OIDC

    # Query RP for auth
    ok( $res = $rp->_get( '/', query => 'test=oidc', accept => 'text/html' ),
        'Unauth RP request' );
    count(1);
    my $url;
    ( $url, $query ) =
      expectRedirection( $res,
        qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

    # Push request to OP
    ok( $res = $op->_get( $url, query => $query, accept => 'text/html' ),
        "Push request to OP,         endpoint $url" );
    count(1);
    expectOK($res);

    # Try to authenticate to OP
    $query = "user=dwho&password=dwho&$query";
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

    ok(
        $res = $rp->_get(
            '/',
            query  => $query,
            accept => 'text/html',
            cookie => 'lemonldappdata=%7B%22_choice%22%3A%22oidc%22%7D'
        ),
        'Call openidconnectcallback on RP'
    );
    count(1);
    my $spId = expectCookie($res);
}
clean_sessions();
done_testing( count() );

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                domain                          => 'idp.com',
                portal                          => 'http://auth.op.com/',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => "1",
                oidcRPMetaDataExportedVars      => {
                    rp => {
                        email       => "mail",
                        family_name => "cn",
                        name        => "cn",
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
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "RS256",
                        oidcRPMetaDataOptionsBypassConsent     => 0,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
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
                domain            => 'rp.com',
                portal            => 'http://auth.rp.com/',
                authentication    => 'Choice',
                userDB            => 'Same',
                passwordDB        => 'Null',
                restSessionServer => 1,

                authChoiceParam   => 'test',
                authChoiceModules => {
                    sql  => 'DBI;DBI;Null',
                    demo => 'Demo;Demo;Null',
                    oidc => 'OpenIDConnect;DBI;Null;;;{"userPivot":"mobile_id"}',
                },

                dbiAuthChain        => "dbi:SQLite:dbname=$userdb",
                dbiAuthUser         => '',
                dbiAuthPassword     => '',
                dbiAuthTable        => 'users',
                dbiAuthLoginCol     => 'login',
                dbiAuthPasswordCol  => 'password',
                dbiAuthPasswordHash => '',

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

use Test::More;
use strict;
use IO::String;
use JSON qw(to_json from_json);

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                       => 'error',
            authentication                 => 'Demo',
            userDB                         => 'Same',
            https                          => 0,
            loginHistoryEnabled            => 0,
            brutForceProtection            => 0,
            portalMainLogo                 => 'common/logos/logo_llng_old.png',
            requireToken                   => 0,
            checkUser                      => 0,
            securedCookie                  => 0,
            checkUserDisplayPersistentInfo => 0,
            checkUserDisplayEmptyValues    => 0,
            contextSwitchingRule           => 1,
            contextSwitchingStopWithLogout => 0,
            contextSwitchingIdRule         => '$uid ne "msmith"',
            contextSwitchingUnrestrictedUsersRule => '$uid eq "dwho"',
        }
    }
);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'user', 'password' );

$query =~ s/user=/user=rtyler/;
$query =~ s/password=/password=rtyler/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);
my $id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

# Get Menu
# ------------------------
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Menu',
);
count(1);
expectOK($res);
ok(
    $res->[2]->[0] =~ m%<span trspan="connectedAs">Connected as</span> rtyler%,
    'Connected as rtyler'
) or print STDERR Dumper( $res->[2]->[0] );
expectAuthenticatedAs( $res, 'rtyler' );
ok(
    $res->[2]->[0] =~
      m%<span trspan="contextSwitching_ON">contextSwitching_ON</span>%,
    'contextSwitching allowed'
) or print STDERR Dumper( $res->[2]->[0] );
count(2);

# ContextSwitching form
# ------------------------
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'ContextSwitching form',
);

( $host, $url, $query ) =
  expectForm( $res, undef, '/switchcontext', 'spoofId' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
    'Found trspan="contextSwitching_ON"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );
count(2);

## POST form
$query =~ s/spoofId=/spoofId=dwho/;
ok(
    $res = $client->_post(
        '/switchcontext',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html',
    ),
    'POST switchcontext'
);
expectRedirection( $res, 'http://auth.example.com/' );
my $id2 = expectCookie($res);
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id2",
        accept => 'text/html'
    ),
    'Get Menu',
);
expectAuthenticatedAs( $res, 'dwho' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_OFF">%,
    'Found trspan="contextSwitching_OFF"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_OFF"' );
count(3);

# Stop ContextSwitching
# ------------------------
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id2",
        accept => 'text/html'
    ),
    'Stop context switching',
);
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id2",
        accept => 'text/html'
    ),
    'Get Menu',
);
ok( $res->[2]->[0] =~ m%<span trmsg="1">%, 'SESSIONEXPIRED' )
  or explain( $res->[2]->[0], 'SESSIONEXPIRED' );
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Menu',
);
expectAuthenticatedAs( $res, 'rtyler' );
count(4);

# ContextSwitching form
# ------------------------
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'ContextSwitching form',
);

( $host, $url, $query ) =
  expectForm( $res, undef, '/switchcontext', 'spoofId' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
    'Found trspan="contextSwitching_ON"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );
count(2);

## POST form
$query =~ s/spoofId=/spoofId=msmith/;
ok(
    $res = $client->_post(
        '/switchcontext',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html',
    ),
    'POST switchcontext'
);
ok( $res->[2]->[0] =~ m%<span trmsg="40">%, 'MALFORMEDUSER' )
  or explain( $res->[2]->[0], 'MALFORMEDUSER' );
count(2);

## Try to authenticate with an unresticted user
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
( $host, $url, $query ) = expectForm( $res, '#', undef, 'user', 'password' );

$query =~ s/user=/user=dwho/;
$query =~ s/password=/password=dwho/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
count(2);
$id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

# ContextSwitching form
# ------------------------
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'ContextSwitching form',
);

( $host, $url, $query ) =
  expectForm( $res, undef, '/switchcontext', 'spoofId' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
    'Found trspan="contextSwitching_ON"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );
count(2);

## POST form with a forbidden identity
$query =~ s/spoofId=/spoofId=msmith/;
ok(
    $res = $client->_post(
        '/switchcontext',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html',
    ),
    'POST switchcontext'
);
expectRedirection( $res, 'http://auth.example.com/' );
$id2 = expectCookie($res);
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id2",
        accept => 'text/html'
    ),
    'Get Menu',
);
expectAuthenticatedAs( $res, 'msmith' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_OFF">%,
    'Found trspan="contextSwitching_OFF"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_OFF"' );
count(3);

$client->logout($id);
$client->logout($id2);

clean_sessions();
done_testing( count() );

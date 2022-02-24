use Test::More;
use strict;
use IO::String;
use JSON;

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
            requireToken                   => 1,
            checkUser                      => 1,
            securedCookie                  => 0,
            checkUserDisplayPersistentInfo => 0,
            checkUserDisplayEmptyValues    => 0,
            contextSwitchingRule           => 1,
            contextSwitchingIdRule         => 1,
            contextSwitchingStopWithLogout => 1,
            contextSwitchingPrefix         => 'testPrefix_',
        }
    }
);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'token' );

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
count(1);

( $host, $url, $query ) =
  expectForm( $res, undef, '/switchcontext', 'spoofId', 'token' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
    'Found trspan="contextSwitching_ON"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );
$query =~ s/spoofId=/spoofId=dwho/;

## POST form with an expired token
# Waiting
Time::Fake->offset("+125s");
ok(
    $res = $client->_post(
        '/switchcontext',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html',
    ),
    'POST expired switchcontext'
);
ok( $res->[2]->[0] =~ m%<span trmsg="82"></span>%, 'Found "<span trmsg="82">"' )
  or explain( $res->[2]->[0], '<span trmsg="82">' );
count(3);

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
count(1);

( $host, $url, $query ) =
  expectForm( $res, undef, '/switchcontext', 'spoofId', 'token' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
    'Found trspan="contextSwitching_ON"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );

## POST form with a valid token
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
count(3);

expectAuthenticatedAs( $res, 'dwho' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_OFF">%,
    'Found trspan="contextSwitching_OFF"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_OFF"' );
ok(
    $res = $client->_get(
        '/checkuser',
        cookie => "lemonldap=$id2",
        accept => 'text/html'
    ),
    'CheckUser form',
);
count(2);

( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url', 'token' );
ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%, 'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUser"' );
ok( $res->[2]->[0] =~ m%<td scope="row">_user</td>%, 'Found attribute _user' )
  or explain( $res->[2]->[0], 'Attribute _user' );
ok( $res->[2]->[0] =~ m%<td scope="row">dwho</td>%, 'Found value dwho' )
  or explain( $res->[2]->[0], 'Value dwho' );
ok( $res->[2]->[0] =~ m%<td scope="row">mail</td>%, 'Found attribute mail' )
  or explain( $res->[2]->[0], 'Attribute mail' );
ok( $res->[2]->[0] =~ m%<td scope="row">testPrefix__session_id</td>%,
    'Found spoofed _id_session' )
  or explain( $res->[2]->[0], 'Spoofed _id_session' );
count(5);

ok(
    $res = $client->_get(
        '/checkuser', cookie => "lemonldap=$id2",
    ),
    'CheckUser form',
);
eval { $res = JSON::from_json( $res->[2]->[0] ) };
ok( not($@), 'Content is JSON' )
  or explain( $res->[2]->[0], 'JSON content' );
my @switching_id = map { $_->{key} eq 'testPrefix__session_id' ? $_ : () }
  @{ $res->{ATTRIBUTES} };
ok( $switching_id[0]->{value} eq $id, 'Good switching_id found' )
  or explain( $switching_id[0]->{value}, 'Switching_id' );
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
ok( $res->[2]->[0] =~ /trmsg="47"/, 'Found logout message' );
count(2);

clean_sessions();
done_testing( count() );

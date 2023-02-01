use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                => 'error',
            useSafeJail             => 1,
            stayConnected           => '$env->{REMOTE_ADDR} eq "127.0.0.1"',
            loginHistoryEnabled     => 1,
            securedCookie           => 1,
            stayConnectedTimeout    => 1000,
            stayConnectedCookieName => 'llngpersistent',
            portalMainLogo          => 'common/logos/logo_llng_old.png',
            accept                  => 'text/html',
        }
    }
);

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho&stayconnected=1'),
        length => 39
    ),
    'Auth query'
);
count(1);
my $id = expectCookie($res);
my ( $host, $url, $query ) =
  expectForm( $res, undef, '/registerbrowser', 'fg', 'token' );

# Push fingerprint with an expired token
$query =~ s/fg=/fg=aaa/;
Time::Fake->offset("+130s");
ok(
    $res = $client->_post(
        '/registerbrowser',
        IO::String->new($query),
        length => length($query),
        cookie => "lemonldap=$id",
        accept => 'text/html',
    ),
    'Post fingerprint'
);
expectRedirection( $res, 'http://auth.example.com/' );
count(1);

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho&stayconnected=1'),
        length => 39
    ),
    'Auth query'
);
count(1);
$id = expectCookie($res);
( $host, $url, $query ) =
  expectForm( $res, undef, '/registerbrowser', 'fg', 'token' );

# Push fingerprint
$query =~ s/fg=/fg=aaa/;
ok(
    $res = $client->_post(
        '/registerbrowser',
        IO::String->new($query),
        length => length($query),
        cookie => "lemonldap=$id",
        accept => 'text/html',
    ),
    'Post fingerprint'
);
expectRedirection( $res, 'http://auth.example.com/' );
my $cid = expectCookie( $res, 'llngpersistent' );
ok( $res->[1]->[5] =~ /\bsecure\b/, ' Secure cookie found' )
  or explain( $res->[1]->[5], 'Secure cookie found' );
count(2);

# Try to connect with persistent connection cookie
ok(
    $res = $client->_get(
        '/',
        cookie => "llngpersistent=$cid",
        accept => 'text/html',
    ),
    'Try to auth with persistent cookie'
);
count(1);
expectOK($res);
( $host, $url, $query ) = expectForm( $res, '#', undef, 'fg', 'token' );

# Push fingerprint
$query =~ s/fg=/fg=aaa/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "llngpersistent=$cid",
        length => length($query),
        accept => 'text/html',
    ),
    'Post fingerprint'
);
count(1);
expectRedirection( $res, 'http://auth.example.com/' );
$id = expectCookie($res);

# Try to connect with persistent connection cookie and an expired token
ok(
    $res = $client->_get(
        '/',
        cookie => "llngpersistent=$cid",
        accept => 'text/html',
    ),
    'Try to auth with persistent cookie and an expired token'
);
count(1);
expectOK($res);
( $host, $url, $query ) = expectForm( $res, '#', undef, 'fg', 'token' );
Time::Fake->offset("+250s");

# Push fingerprint
$query =~ s/fg=/fg=aaa/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "llngpersistent=$cid",
        length => length($query),
        accept => 'text/html',
    ),
    'Post fingerprint with an expired token'
);
( $host, $url, $query ) = expectForm($res);
ok( $query =~ /user/, ' Get login form' );
count(2);

# Try to connect with persistent connection cookie but with bad fingerprint
ok(
    $res = $client->_get(
        '/',
        cookie => "llngpersistent=$cid",
        accept => 'text/html',
    ),
    'Try to auth with persistent cookie'
);
count(1);
expectOK($res);
( $host, $url, $query ) = expectForm( $res, '#', undef, 'fg', 'token' );

# Push fingerprint
$query =~ s/fg=/fg=aaaa/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "llngpersistent=$cid",
        length => length($query),
        accept => 'text/html',
    ),
    'Post bad fingerprint'
);
( $host, $url, $query ) = expectForm($res);
ok( $query =~ /user/, ' Get login form' );
expectCookie( $res, 'llngpersistent' );
my @connexionCookie = grep /llngpersistent/, @{ $res->[1] };
ok( $connexionCookie[0] =~ /secure/ && $connexionCookie[0] =~ /21 Oct 2015/,
    'Found secure and expired connexion Cookie' )
  or explain( $connexionCookie[0], 'Secure and expired cookie' );
count(3);

# Try to authenticate with history
# --------------------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'user=dwho&password=dwho&stayconnected=1&checkLogins=1'),
        length => 53
    ),
    'Auth query'
);
count(1);
$id = expectCookie($res);
( $host, $url, $query ) =
  expectForm( $res, undef, '/registerbrowser', 'fg', 'token' );

# Push fingerprint
$query =~ s/fg=/fg=aaa/;
ok(
    $res = $client->_post(
        '/registerbrowser',
        IO::String->new($query),
        length => length($query),
        cookie => "lemonldap=$id",
        accept => 'text/html',
    ),
    'Post fingerprint'
);
count(1);
$cid = expectCookie( $res, 'llngpersistent' );

ok( $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
    'Found custom main Logo' )
  or explain( $res->[2]->[0], 'Custom main logo' );
ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
  or explain( $res->[2]->[0], 'trspan="lastLogins"' );
my @c = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );

# History with 2 successLogins
ok( @c == 3, " -> Three entries found" )
  or explain( $res->[2]->[0], 'Three entries found' );
ok( $res = $client->_get( '/', cookie => "lemonldap=$id" ),
    'Verify connection' );
expectAuthenticatedAs( $res, 'dwho' );
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Menu'
);
ok( $res->[2]->[0] =~ m%<span trspan="yourApps">Your applications</span>%,
    ' Apps menu found' )
  or explain( $res->[2]->[0], 'Apps menu' );
count(6);
expectOK($res);

# Try to connect with an expired persistent connection cookie
Time::Fake->offset("+1300s");
ok(
    $res = $client->_get(
        '/',
        cookie => "llngpersistent=$cid",
        accept => 'text/html',
    ),
    'Try to auth with an expired persistent session cookie'
);
( $host, $url, $query ) = expectForm($res);
ok( $query =~ /user/, ' Get login form' );
count(2);

# Push fingerprint
$query =~ s/fg=/fg=aaa/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "llngpersistent=$cid",
        length => length($query),
        accept => 'text/html',
    ),
    'Post fingerprint with an expired persistent connexion cookie'
);
( $host, $url, $query ) = expectForm($res);
ok( $query =~ /user/, ' Get login form' );
count(2);

clean_sessions();

done_testing( count() );


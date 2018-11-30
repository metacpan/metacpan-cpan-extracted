use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new(
    {
        ini => {
            logLevel      => 'error',
            useSafeJail   => 1,
            stayConnected => 1,
            accept        => 'text/html',
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
expectRedirection( $res, 'http://auth.example.com/' );
my $cid = expectCookie( $res, 'llngconnexion' );

$client->logout($id);

# Try to connect with persistent connection cookie
ok(
    $res = $client->_get(
        '/',
        cookie => "llngconnexion=$cid",
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
        cookie => "llngconnexion=$cid",
        length => length($query),
        accept => 'text/html',
    ),
    'Post fingerprint'
);
count(1);
expectRedirection( $res, 'http://auth.example.com/' );
$id = expectCookie($res);

$client->logout($id);

# Try to connect with persistent connection cookie but bad fingerprint
ok(
    $res = $client->_get(
        '/',
        cookie => "llngconnexion=$cid",
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
        cookie => "llngconnexion=$cid",
        length => length($query),
        accept => 'text/html',
    ),
    'Post bad fingerprint'
);
count(1);
( $host, $url, $query ) = expectForm($res);
ok( $query =~ /user/, ' Get login form' );
count(1);

clean_sessions();

done_testing( count() );


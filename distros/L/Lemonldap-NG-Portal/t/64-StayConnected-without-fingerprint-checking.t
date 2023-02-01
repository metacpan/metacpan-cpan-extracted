use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel              => 'error',
            useSafeJail           => 1,
            stayConnected         => 1,
            stayConnectedBypassFG => 1,
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
my $cid = expectCookie( $res, 'llngconnection' );
ok( $res->[1]->[5] =~ /\bHttpOnly=1\b/, ' HTTP cookie found' )
  or explain( $res->[1]->[5], 'HTTP cookie found' );
count(2);

# Try to connect with persistent connection cookie
ok(
    $res = $client->_get(
        '/',
        cookie => "llngconnection=$cid",
        accept => 'text/html',
    ),
    'Try to auth with persistent cookie'
);
count(1);
expectOK($res);
( $host, $url, $query ) = expectForm( $res, '#', undef, 'fg', 'token' );

# Push new fingerprint
$query =~ s/fg=/fg=bbb/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "llngconnection=$cid",
        length => length($query),
        accept => 'text/html',
    ),
    'Post new fingerprint'
);
count(1);
expectRedirection( $res, 'http://auth.example.com/' );
$id = expectCookie($res);

$client->logout($id);
clean_sessions();

done_testing( count() );


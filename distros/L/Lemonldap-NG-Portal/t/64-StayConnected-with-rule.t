use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel      => 'error',
            useSafeJail   => 1,
            requireToken  => 1,
            stayConnected => '$env->{REMOTE_ADDR} =~ /^127\.0\.0/'
        }
    }
);
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Firt access' );
my ( $host, $url, $query ) =
  expectForm( $res, undef, undef, 'user', 'password', 'stayconnected',
    'checkLogins', 'token' );
ok( $res = $client->_get( '/', ip => '10.10.10.10', accept => 'text/html' ),
    'Access from external LAN' );
( $host, $url, $query ) =
  expectForm( $res, undef, undef, 'user', 'password', 'checkLogins', 'token' );
count(2);

$query =~ s/user=/user=dwho/;
$query =~ s/password=/password=dwho/;

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        ip     => '10.10.10.10',
        accept => 'text/html',
        length => length($query)
    ),
    'Auth query'
);
count(1);
my $id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

# Try to push fingerprint
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

$client->logout($id);
clean_sessions();
done_testing( count() );


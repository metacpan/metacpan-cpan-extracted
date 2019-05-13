use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel              => 'error',
            useSafeJail           => 1,
            requireToken          => '"Bad rule"',
            tokenUseGlobalStorage => 1,
        }
    }
);

# Test normal first access
# ------------------------
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Unauth request' );
count(1);

my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
ok( $query =~ /token=([^&]+)/, 'Token value' );
count(1);
my $token = $1;
$query =~ "token=$token";

# Try to auth without token
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23
    ),
    'Try to auth without token'
);
count(1);
expectReject($res);

# Try token as cookie value
ok( $res = $client->_get( '/', cookie => "lemonldap=$token" ),
    'Try token as cookie' );
count(1);
expectReject($res);

# Try to auth with token
$query .= '&user=dwho&password=dwho';
ok(
    $res =
      $client->_post( '/', IO::String->new($query), length => length($query) ),
    'Try to auth with token'
);
count(1);
expectOK($res);
my $id = expectCookie($res);

# Verify auth
ok( $res = $client->_get( '/', cookie => "lemonldap=$id" ), 'Verify auth' );
count(1);
expectOK($res);

# Try to reuse the same token
ok(
    $res =
      $client->_post( '/', IO::String->new($query), length => length($query) ),
    'Try to reuse the same token'
);
expectReject($res);
ok(
    $res = $client->_post(
        '/', IO::String->new($query),
        length => length($query),
        accept => 'text/html'
    ),
    'Verify that there is a new token'
);
expectForm( $res, '#', undef, 'token' );
count(2);

clean_sessions();

done_testing( count() );

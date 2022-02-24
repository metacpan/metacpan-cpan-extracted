use Test::More;
use strict;
use IO::String;
use Test::MockObject;

require 't/test-lib.pm';

my $res;
my $mock   = Test::MockObject->new();
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            authentication => 'Radius',
            userDB         => 'Demo',
            radiusServer   => '127.0.0.1',
            radiusSecret   => 'test',
            requireToken   => 1
        }
    }
);

# Test normal first access
ok( $res = $client->_get( '/', accept => 'text/html' ), 'First request' );
count(1);
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'token' );

# Fake Radius server (bad password)
$mock->fake_module( 'Authen::Radius', check_pwd => sub { 0 } );

# Try to authenticate with bad password
$query =~ s/user=[^&]*/user=dwho/;
$query =~ s/password=/password=jdoe/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html'
    ),
    'Auth query'
);
count(1);
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'token' );

# Fake Radius server
$mock->fake_module( 'Authen::Radius', check_pwd => sub { 1 } );

# Try to authenticate
$query =~ s/user=[^&]*/user=dwho/;
$query =~ s/password=/password=dwho/;
ok(
    $res = $client->_post(
        '/', IO::String->new($query), length => length($query)
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Portal menu'
);
count(1);
expectAuthenticatedAs( $res, 'dwho' );
$client->logout($id);

clean_sessions();
done_testing( count() );

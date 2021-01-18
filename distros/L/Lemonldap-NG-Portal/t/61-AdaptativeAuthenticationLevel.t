use Test::More;
use strict;
use IO::String;
use Data::Dumper;

BEGIN {
    require 't/test-lib.pm';
}

my $res;
my $id;
my $json;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                           => 'error',
            authentication                     => 'Demo',
            userDB                             => 'Same',
            adaptativeAuthenticationLevelRules => {
                '$uid eq "dwho"'   => '+2',
                '$uid eq "msmith"' => '=5',
            },
            restSessionServer => 1,
        }
    }
);

ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        accept => 'text/html',
        length => 23
    ),
    'Auth query'
);
count(1);
$id = expectCookie($res);

ok(
    $res = $client->_get(
        '/session/my/global', cookie => "lemonldap=$id"
    ),
    'Get session'
);
count(1);
$json = expectJSON($res);

ok( $json->{authenticationLevel} == 3, 'Authentication level upgraded' );
count(1);

ok( $client->logout($id), 'Logout' );
count(1);

ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=msmith&password=msmith'),
        accept => 'text/html',
        length => 27
    ),
    'Auth query'
);
count(1);
$id = expectCookie($res);

ok(
    $res = $client->_get(
        '/session/my/global', cookie => "lemonldap=$id"
    ),
    'Get session'
);
count(1);
$json = expectJSON($res);

ok( $json->{authenticationLevel} == 5, 'Authentication level upgraded' );
count(1);

ok( $client->logout($id), 'Logout' );
count(1);

clean_sessions();

done_testing( count() );

use Test::More;
use strict;
use IO::String;
use Data::Dumper;

BEGIN {
    require 't/test-lib.pm';
}

my ( $res, $id, $json );

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
            exportedAttr      => '+ mail uid _session_id'
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

ok( $json->{uid} eq 'dwho', 'uid found' ) or explain( $json, "uid='dwho'" );
ok( $json->{authenticationLevel} == 3, 'Authentication level upgraded' );
ok( scalar keys %$json == 10,          'Ten exported attributes found' )
  or explain( $json, 'Ten exported attributes' );
count(3);

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

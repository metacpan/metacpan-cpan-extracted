use warnings;
use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new(
    {
        ini => {
            logLevel             => 'error',
            authentication       => 'Demo',
            userDB               => 'Same',
            loginHistoryEnabled  => 0,
            bruteForceProtection => 0,
            requireToken         => 0,
            globalLogoutRule     => 1,
        }
    }
);

## First successful connection for 'dwho'
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    '1st "dwho" Auth query'
);
count(1);
my $idd = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

## Second successful connection for "dwho"
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    '2nd "dwho" Auth query'
);
count(1);
expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

## Third successful connection for 'dwho'
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    '3rd "dwho" Auth query'
);
count(1);
expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

## Logout request for 'dwho'
ok(
    $res = $client->_get(
        '/',
        query  => 'logout',
        cookie => "lemonldap=$idd"
    ),
    'Logout request for "dwho"'
);
eval { $res = JSON::from_json( $res->[2]->[0] ) };
ok( not($@), 'Content is JSON' )
  or explain( $res->[2]->[0], 'JSON content' );
ok( $res->{globalLogout} == 3, '3 active sessions found' );
ok( $res->{confirmationRequired} == 1, 'Confirmation required' );
count(4);

## Logout request for 'dwho' with confirmation param
ok(
    $res = $client->_get(
        '/',
        query  => 'logout&confirm=1',
        cookie => "lemonldap=$idd"
    ),
    'Confirmed logout request for "dwho"'
);
eval { $res = JSON::from_json( $res->[2]->[0] ) };
ok( not($@), 'Content is JSON' )
  or explain( $res->[2]->[0], 'JSON content' );
ok( $res->{error} == 47, 'PE_LOGOUT_OK' );
my $nbr = count_sessions();
ok( $nbr == 0, "No session found" )
  or explain("Number of session(s) found = $nbr");
count(4);

clean_sessions();

done_testing( count() );

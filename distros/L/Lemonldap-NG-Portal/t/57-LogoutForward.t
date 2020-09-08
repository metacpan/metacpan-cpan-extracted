use Test::More;
use strict;
use IO::String;
use Data::Dumper;

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel             => 'error',
            authentication       => 'Demo',
            userDB               => 'Same',
            loginHistoryEnabled  => 0,
            bruteForceProtection => 0,
            requireToken         => 0,
            restSessionServer    => 1,
            logoutServices       => { 'mytest' => 'http://auth.example.com/' }
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
my @idd;
$idd[0] = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

## Logout request for 'dwho'
ok(
    $res = $client->_get(
        '/',
        query  => 'logout',
        cookie => "lemonldap=$idd[0]",
        accept => 'text/html'
    ),
    'Logout request for "dwho"'
);
count(1);

ok(
    $res->[2]->[0] =~
      m%<h3 trspan="logoutFromOtherApp">logoutFromOtherApp</h3>%,
    'Found Logout Forward page'
) or explain( $res->[2]->[0], "PE_LOGOUT_OK" );
count(1);
$client->logout( $idd[0] );

clean_sessions();

done_testing( count() );


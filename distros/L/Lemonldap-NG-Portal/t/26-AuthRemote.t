use Test::More;
use strict;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                   => 'error',
            useSafeJail                => 1,
            authentication             => 'Remote',
            userDB                     => 'Same',
            remoteUserField            => 'uid',
            remoteGlobalStorage        => 'Apache::Session::File',
            remoteGlobalStorageOptions => {
                Directory     => 't/sessions2',
                LockDirectory => 't/sessions2/lock',
            },
            remotePortal => 'http://auth2.example.com',
        }
    }
);

# Test redirection to remote portal
ok( $res = $client->_get( '/', accept => 'text/html' ), 'First request' );
count(1);
expectRedirection( $res,
    'http://auth2.example.com?url=aHR0cDovL2F1dGguZXhhbXBsZS5jb20v' );

ok(
    $res = $client->_get(
        '/',
        query =>
'lemonldap=6e30af4ffa5689b3e49a104d1b160d316db2b2161a0f45776994eed19dbdc101'
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);

clean_sessions();

done_testing( count() );

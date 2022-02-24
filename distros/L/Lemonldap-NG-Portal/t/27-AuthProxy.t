use Test::More;
use strict;
use IO::String;

my $res;
my $maintests = 2;
require 't/test-lib.pm';

SKIP: {
    skip 'REMOTELLNG is not set', $maintests unless ( $ENV{REMOTELLNG} );
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel         => 'error',
                useSafeJail      => 1,
                authentication   => 'Proxy',
                userDB           => 'Same',
                proxyAuthService => $ENV{REMOTELLNG},
            }
        }
    );
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23
        ),
        'Auth query'
    );
    expectOK($res);
    my $id = expectCookie($res);

    $client->logout($id);
    clean_sessions();
}
count($maintests);
done_testing( count() );

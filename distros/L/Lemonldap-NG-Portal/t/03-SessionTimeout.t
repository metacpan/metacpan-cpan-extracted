use Test::More;
use strict;
use IO::String;
use lib 't/lib';

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel             => 'error',
            useSafeJail          => 1,
            globalStorage        => 'Apache::Session::Timeout',
            globalStorageOptions => {
                Directory     => 't/sessions',
                LockDirectory => 't/sessions/lock',
                timeout       => 1,
            },
        }
    }
);

# Try to authenticate with good password
# --------------------------------------
diag 'Waiting';
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
    ),
    'Auth query'
);
count(1);
expectReject( $res, 401, 8 );

clean_sessions();

done_testing( count() );

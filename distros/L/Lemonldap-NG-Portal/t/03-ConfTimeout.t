use Test::More;
use strict;
use IO::String;
use lib 't/lib';

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        confFailure => 1,
        ini         => {
            configStorage => {
                type        => 'Timeout',
                dirName     => 't',
                confTimeout => 1,
            },
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

diag "Waiting";
ok( !$client->{p}->init( $client->ini ) );
ok( $client->app( $client->{p}->run ) );
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
    ),
    'Auth query'
);
ok( $res->[0] == 500 );
count(4);
clean_sessions();

done_testing( count() );

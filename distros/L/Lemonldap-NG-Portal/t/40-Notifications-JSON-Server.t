use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

eval { unlink 't/20160530_dwho_dGVzdHJlZg==.json' };

my $json = '{
"date": "2016-05-30",
"reference": "testref",
"uid": "dwho",
"title": "Test title",
"text": "This is a test text"
}';

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                   => 'error',
            useSafeJail                => 1,
            notification               => 1,
            notificationServer         => 1,
            notificationStorage        => 'File',
            notificationStorageOptions => {
                dirName => 't'
            },
        }
    }
);

my $res;
ok(
    $res = $client->_post(
        '/notifications', IO::String->new($json),
        type   => 'application/json',
        length => length($json)
    ),
    'Create notification'
);
count(1);

# Try yo authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'user=dwho&password=dwho&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw=='),
        accept => 'text/html',
        length => 64,
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);
expectForm( $res, undef, '/notifback', 'reference1x1', 'url' );

eval { unlink 't/20160530_dwho_dGVzdHJlZg==.json' };

clean_sessions();
done_testing( count() );

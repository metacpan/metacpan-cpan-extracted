use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            authentication => 'Demo',
            userDB         => 'Same',
            singleSession  => 1,
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
count(1);
expectOK($res);
my $id1 = expectCookie($res);

ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id2 = expectCookie($res);

ok( $res = $client->_get( '/', cookie => "lemonldap=$id2" ), 'Use id 2' );
count(1);
expectOK($res);

ok( $res = $client->_get( '/', cookie => "lemonldap=$id1" ), 'Use id 1' );
count(1);
expectReject($res);

clean_sessions();

done_testing( count() );

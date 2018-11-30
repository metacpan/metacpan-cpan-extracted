# Test RSA key generation

use Test::More;
use strict;
use JSON;
use IO::String;
require 't/test-lib.pm';

my $res;
ok(
    $res = &client->_post(
        '/confs/newRSAKey', '', IO::String->new(''), 'application/json', 0,
    ),
    "Request succeed"
);
ok( $res->[0] == 200, "Result code is 200" );
my $key;
ok( $key = from_json( $res->[2]->[0] ), 'Response is JSON' );
count(3);

ok(
    $res = &client->_post(
        '/confs/newRSAKey', '', IO::String->new('{"password":"hello"}'),
        'application/json', 20,
    ),
    "Request succeed"
);
ok( $res->[0] == 200, "Result code is 200" );
ok( $key = from_json( $res->[2]->[0] ), 'Response is JSON' );
count(3);

done_testing( count() );

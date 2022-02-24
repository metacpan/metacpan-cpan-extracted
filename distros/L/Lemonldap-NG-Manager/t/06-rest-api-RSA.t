# Test RSA key generation

use Test::More;
use strict;
use JSON;
use IO::String;
require 't/test-lib.pm';

sub checkResult {
    my $res        = shift;
    my $expecthash = shift;
    ok( $res->[0] == 200, "Result code is 200" );
    my $key;
    ok( $key = from_json( $res->[2]->[0] ), 'Response is JSON' );
    like( $key->{private}, qr/BEGIN/, "is PEM formatted" );
    like( $key->{public},  qr/BEGIN/, "is PEM formatted" );
    ok( $key->{hash}, "hash is non empty" ) if $expecthash;
    count(1)                                if $expecthash;
    count(4);
}

my $res;
ok(
    $res = &client->_post(
        '/confs/newRSAKey', '', IO::String->new(''), 'application/json', 0,
    ),
    "Request succeed"
);
count(1);
checkResult( $res, 1 );

ok(
    $res = &client->_post(
        '/confs/newRSAKey', '', IO::String->new('{"password":"hello"}'),
        'application/json', 20,
    ),
    "Request succeed"
);
count(1);
checkResult( $res, 1 );

ok(
    $res = &client->_post(
        '/confs/newCertificate', '',
        IO::String->new(''),     'application/json',
        0,
    ),
    "Request succeed"
);
count(1);
checkResult($res);

ok(
    $res = &client->_post(
        '/confs/newCertificate', '', IO::String->new('{"password":"hello"}'),
        'application/json',      20,
    ),
    "Request succeed"
);
count(1);
checkResult($res);

done_testing( count() );

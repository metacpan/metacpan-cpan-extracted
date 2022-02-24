use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

my ( $client, $res, $id );

$client = LLNG::Manager::Test->new(
    { ini => { logLevel => 'error', restSessionServer => 0 } } );

# Try to authenticate
# -------------------
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
$id = expectCookie($res);

# Test mysession endpoint
ok(
    $res = $client->_get(
        '/mysession',
        query  => 'authorizationfor=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29t',
        cookie => "lemonldap=$id"
    ),
    'Check for test1'
);
count(1);
expectOK($res);
$res = eval { JSON::from_json( $res->[2]->[0] ) };
if ($@) {
    fail("Bad JSON response: $@");
    count(1);
}
ok( $res->{result} == 1, ' http//test1.example.com is ganted' );
count(1);

ok(
    $res = $client->_get(
        '/mysession',
        query  => 'authorizationfor=aHR0cDovL3Rlc3Q0LmV4YW1wbGUuY29t',
        cookie => "lemonldap=$id"
    ),
    'Check for test1'
);
count(1);
expectOK($res);

# Test myapplications endpoint
ok(
    $res = $client->_get(
        '/myapplications', cookie => "lemonldap=$id"
    ),
    'Request for my applications'
);
count(1);
expectOK($res);
$res = eval { JSON::from_json( $res->[2]->[0] ) };
if ($@) {
    fail("Bad JSON response: $@");
    count(1);
}
ok( $res->{result} == 1, ' Result == 1' );
count(1);
ok( $res->{myapplications}->[0]->{Category} eq 'Sample applications',
    ' "Sample applications" category found' );
ok( scalar @{ $res->{myapplications}->[0]->{Applications} } == 2,
    ' Two applications found' );
ok(
    $res->{myapplications}->[0]->{Applications}->[0]->{'Application Test 1'}
      ->{AppDesc} eq 'A simple application displaying authenticated user',
    ' Description app1 found'
);
ok(
    $res->{myapplications}->[0]->{Applications}->[1]->{'Application Test 2'}
      ->{AppUri} =~ m#http://test2\.example\.com/#,
    ' URI app2 found'
);
count(4);

# Test logout
$client->logout($id);

#print STDERR Dumper($res);

clean_sessions();

done_testing( count() );

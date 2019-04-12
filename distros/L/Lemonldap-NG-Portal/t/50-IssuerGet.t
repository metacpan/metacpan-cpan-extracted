use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel              => 'error',
            useSafeJail           => 1,
            issuerDBGetActivation => 1,
            issuerDBGetRule       => '$uid eq "dwho"',
            issuerDBGetPath       => '^/test/',
            issuerDBGetParameters =>
              { 'test1.example.com' => { ID => '_session_id' } }
        }
    }
);

# Try to authenticate with an unauthorized user
# ---------------------------------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=rtyler&password=rtyler'),
        length => 27
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);

# Test GET login
ok(
    $res = $client->_get(
        '/test',
        query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'GET request with good url'
);
count(1);
ok( $res->[2]->[0] =~ /trmsg="92"/, 'Reject reason is 92' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);

# Try to authenticate with an authorized user
# -------------------------------------------
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

# Test GET login
ok(
    $res = $client->_get(
        '/test',
        query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'GET request with good url'
);
count(1);
expectRedirection( $res, "http://test1.example.com/?ID=$id" );

# Test not logged access
ok(
    $res = $client->_get(
        '/test', query => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==',
    ),
    'Not logged access'
);
count(1);
expectReject($res);

clean_sessions();

done_testing( count() );

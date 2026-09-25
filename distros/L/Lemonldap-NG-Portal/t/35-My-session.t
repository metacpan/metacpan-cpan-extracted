use warnings;
use Test::More;
use strict;
use IO::String;
use MIME::Base64;
use URI::Escape;

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
    $res->{myapplications}->[0]->{Applications}->[0]->{'Application Test 1'}
      ->{AppLogo} eq 'http://auth.example.com/static/common/apps/demo.png',
    ' Logo app1 found'
);
ok(
    $res->{myapplications}->[0]->{Applications}->[1]->{'Application Test 2'}
      ->{AppUri} =~ m#http://test2\.example\.com/#,
    ' URI app2 found'
);
count(5);

# authorizationfor: the URL is percent-decoded and normalized by the web
# server before the request is routed to the application, so rules must be
# tested against the same canonical value, else they can be bypassed with an
# encoded URL (#3723)
sub authorizationfor {
    my ($url) = @_;
    ok(
        my $res = $client->_get(
            '/mysession',
            query => 'authorizationfor='
              . uri_escape( encode_base64( $url, '' ) ),
            cookie => "lemonldap=$id"
        ),
        "Check for $url"
    );
    count(1);
    expectOK($res);
    return JSON::from_json( $res->[2]->[0] );
}

foreach my $url (
    'http://test1.example.com/deny',           # no encoding
    'http://test1.example.com/%64eny',         # "d" encoded
    'http://test1.example.com/den%79',         # "y" encoded
    'http://test1.example.com/./deny',         # dot segment
    'http://test1.example.com/foo/../deny',    # dot segment
    'http://test1.example.com//deny',          # duplicate slash
    'http://test1.example.com/%2Fdeny',        # encoded slash
  )
{
    is( authorizationfor($url)->{result}, 0, " $url is refused" );
    count(1);
}

# Decoded as /denY: the rule ^/deny doesn't apply
is( authorizationfor('http://test1.example.com/den%59')->{result},
    1, ' http://test1.example.com/den%59 is granted' );
count(1);

# Test logout
$client->logout($id);

#print STDERR Dumper($res);

clean_sessions();

done_testing( count() );

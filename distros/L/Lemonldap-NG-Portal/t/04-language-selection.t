use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

my ( $client, $res, $id );

$client = LLNG::Manager::Test->new( {
        ini => {
            logLevel          => 'error',
            restSessionServer => 1,
            useSafeJail       => 1,
            sameSite          => 'Strict'
        },
    }
);

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23
    ),
    'Auth query without language cookie'
);
count(1);
expectOK($res);
$id = expectCookie($res);

ok( $res = $client->_get("/sessions/global/$id"), 'Get session' );
count(1);
expectOK($res);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
count(1);
ok( $res->{_language} eq 'en', 'Default value for _language' );
count(1);

# Test logout
$client->logout($id);

ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        cookie => "llnglanguage=fr",
        length => 23
    ),
    'Auth query with language cookie'
);
count(1);
expectOK($res);
$id = expectCookie($res);
my $rawCookie = getHeader( $res, 'Set-Cookie' );
ok( $rawCookie =~ /;\s*SameSite=Strict/, 'Found SameSite=Strict (conf)' )
  or explain( $rawCookie, 'SameSite value must be "Strict"' );
count(1);
ok( $res = $client->_get("/sessions/global/$id"), 'Get session' );
count(1);
expectOK($res);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
count(1);
ok( $res->{_language} eq 'fr', 'Correct value for _language' );
count(1);

# Test logout
$client->logout($id);

#print STDERR Dumper($res);

clean_sessions();

done_testing( count() );

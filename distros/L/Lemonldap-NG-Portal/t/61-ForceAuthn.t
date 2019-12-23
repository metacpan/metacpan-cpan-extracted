use Test::More;
use strict;
use IO::String;
use Data::Dumper;

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            authentication           => 'Demo',
            userdb                   => 'Same',
            portalForceAuthn         => 1,
            portalForceAuthnInterval => 5,
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
count(1);

# Skip ahead in time
Time::Fake->offset("+30s");

ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id1",
        accept => 'text/html',
    ),
    'Form ReAuthentication'
);
ok( $res->[2]->[0] =~ qr%<span trspan="PE87"></span>%, 'Found PE87 code' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);

ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
    ),
    'Auth query'
);
count(1);
expectOK($res);
$id1 = expectCookie($res);
count(1);

ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id1",
        accept => 'text/html',
    ),
    'Go to Portal'
);
ok( $res->[2]->[0] =~ qr%<span trspan="yourApps">Your applications</span>%,
    'Found applications list' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);

$client->logout($id1);
clean_sessions();

done_testing( count() );

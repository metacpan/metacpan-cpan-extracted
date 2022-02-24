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
            logLevel                => 'error',
            authentication          => 'Demo',
            userdb                  => 'Same',
            timeoutActivity         => 7200,
            timeoutActivityInterval => 60,
            handlerInternalCache    => 1,
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
expectOK($res);
my $id1 = expectCookie($res);
count(1);

# Skip ahead in time before activity timeout
Time::Fake->offset("+20m");

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
count(2);

# Skip ahead in time after activity timeout
Time::Fake->offset("+3h");

ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id1",
        accept => 'text/html',
    ),
    'Form Authentification'
);
ok( $res->[2]->[0] =~ m%<span trmsg="1">%, 'Found PE_SESSIONEXPIRED code' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

$client->logout($id1);
clean_sessions();

done_testing( count() );

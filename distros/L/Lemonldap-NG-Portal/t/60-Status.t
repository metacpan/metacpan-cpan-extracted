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
            portalStatus   => 1,
            authentication => 'Demo',
            userDB         => 'Same',
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
my $id = expectCookie($res);

ok( $res = $client->_get('/portalStatus'), 'Get status' );
count(1);
expectOK($res);
eval { $res = JSON::from_json( $res->[2]->[0] ) };

ok( !$@, 'Content is JSON' ) or print STDERR Dumper($@);
count(1);

ok( $res->{storage}->{global} == 1,     'Found 1 session' );
ok( $res->{storage}->{persistent} == 1, 'Found 1 persistent session' );
count(2);

clean_sessions();

done_testing( count() );

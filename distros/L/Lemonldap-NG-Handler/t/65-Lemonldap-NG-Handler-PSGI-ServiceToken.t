use Test::More;

BEGIN {
    require 't/test-psgi-lib.pm';
}

init('Lemonldap::NG::Handler::Server');

my $res;

my $crypt = Lemonldap::NG::Common::Crypto->new('qwertyui');

my $token = $crypt->encrypt( join ':', time, $sessionId, 'test1.example.com' );

ok(
    $res = $client->_get(
        '/', undef, 'test1.example.com', undef,
        VHOSTTYPE           => 'ServiceToken',
        'HTTP_X_LLNG_TOKEN' => $token,
    ),
    'Query with token'
);
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );
count(2);

done_testing( count() );

clean();

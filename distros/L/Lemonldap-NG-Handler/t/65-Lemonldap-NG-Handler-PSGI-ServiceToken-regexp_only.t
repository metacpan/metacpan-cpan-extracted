use Test::More;

BEGIN {
    require 't/test-psgi-lib.pm';
}

init(
    'Lemonldap::NG::Handler::Server',
    {
        logLevel               => 'error',
        handlerServiceTokenTTL => 120,
        vhostOptions           => {
            'test1.example.com' => {
                vhostHttps           => 0,
                vhostPort            => 80,
                vhostMaintenance     => 0,
                vhostServiceTokenTTL => 180,
            },
            'test2.example.com' => {
                vhostHttps           => 0,
                vhostPort            => 80,
                vhostMaintenance     => 0,
                vhostServiceTokenTTL => 300,
            }
        },
        exportedHeaders => {
            'test2.example.com' => {
                'Auth-User' => '$uid',
                'empty'     => undef,
                'zero'      => "'0'",
            },
        }
    }
);

my $res;
my $crypt = Lemonldap::NG::Common::Crypto->new('qwertyui');
my $token = $crypt->encrypt(
    join ':',                        time,
    $sessionId,                      '/^test[29]\.example.co/',
);

ok(
    $res = $client->_get(
        '/', undef, 'test2.example.com', undef,
        VHOSTTYPE           => 'ServiceToken',
        'HTTP_X_LLNG_TOKEN' => $token,
    ),
    'Query with token 1'
);
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );
count(2);

ok(
    $res = $client->_get(
        '/', undef, 'test1.example.com', undef,
        VHOSTTYPE           => 'ServiceToken',
        'HTTP_X_LLNG_TOKEN' => $token,
    ),
    'Query with token 2'
);
ok( $res->[0] == 302, 'Code is 302' ) or explain( $res->[0], 302 );
count(2);

done_testing( count() );

clean();

use Test::More;
use Lemonldap::NG::Portal;
use strict;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel         => 'error',
            requireToken     => 1,
            checkStateSecret => 'x',
            checkState       => 1,
            authentication   => 'Combination',
            userDB           => 'Same',

            combination => '[K,Dm] or [Dm]',
            combModules => {
                K => {
                    for  => 1,
                    type => 'Kerberos',
                },
                Dm => {
                    for  => 0,
                    type => 'Demo',
                },
            },
            krbKeytab => '/etc/keytab',
            krbByJs   => 1,
        }
    }
);

ok( $res = $client->_get( '/checkstate', accept => 'application/json' ),
    'Test no secret' );
expectReject( $res, 500, "Bad secret" );

ok(
    $res = $client->_get(
        '/checkstate',
        accept => 'application/json',
        query  => 'secret=xx'
    ),
    'Test bad secret, no user auth'
);
expectReject( $res, 500, "Bad secret" );

ok(
    $res = $client->_get(
        '/checkstate',
        accept => 'application/json',
        query  => 'secret=x'
    ),
    'Test correct secret, no user auth'
);
my $j = expectJSON($res);
is( $j->{result}, 1, "response has a result key with value 1" );
is(
    $j->{version},
    $Lemonldap::NG::Portal::VERSION,
    "response version is correct"
);

ok(
    $res = $client->_get(
        '/checkstate',
        accept => 'application/json',
        query  => 'user=dwho&password=dwho'
    ),
    'Test no secret with user auth'
);
expectReject( $res, 500, "Bad secret" );

ok(
    $res = $client->_get(
        '/checkstate',
        accept => 'application/json',
        query  => 'secret=xx&user=dwho&password=dwho'
    ),
    'Test incorrect secret with user auth'
);
expectReject( $res, 500, "Bad secret" );

ok(
    $res = $client->_get(
        '/checkstate',
        accept => 'application/json',
        query  => 'secret=x&user=dwho&password=davros'
    ),
    'Test correct secret with bad user auth'
);
expectReject( $res, 500, "Bad result during auth: 5" );

is( $j->{result}, 1, "response has a result key with value 1" );
ok(
    $res = $client->_get(
        '/checkstate',
        accept => 'application/json',
        query  => 'secret=x&user=dwho&password=dwho'
    ),
    'Test correct secret with good user auth'
);
$j = expectJSON($res);
is( $j->{result}, 1, "response has a result key with value 1" );

done_testing();

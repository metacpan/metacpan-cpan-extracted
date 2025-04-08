use warnings;
use Test::More;
use Lemonldap::NG::Portal;
use strict;

require 't/test-lib.pm';
SKIP: {
    eval "require GSSAPI";
    if ($@) {
        skip 'GSSAPI not found';
    }

    my $res;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel         => 'error',
                requireToken     => 1,
                checkStateSecret => 'x',
                checkState       => 1,
                authentication   => 'Choice',
                userDB           => 'Same',
                authChoiceModules => {
                    '1_demo' => 'Demo;Demo;Null',
                    '2_ssl'  => 'SSL;Demo;Null',
                },
            }
        }
    );

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

    ok(
        $res = $client->_get(
            '/checkstate',
            accept => 'application/json',
            query  => 'choice=1_demo&secret=x&user=dwho&password=davros'
        ),
        'Test correct secret with bad user auth'
    );
    expectReject( $res, 500, "Bad result during auth: 5" );

    ok(
        $res = $client->_get(
            '/checkstate',
            accept => 'application/json',
            query  => 'secret=x&user=dwho&password=dwho'
        ),
        'Test correct secret with good user auth without choice'
    );
    expectReject( $res, 500, "Bad result during auth: 9" );

    ok(
        $res = $client->_get(
            '/checkstate',
            accept => 'application/json',
            query  => 'choice=3_zz&secret=x&user=dwho&password=dwho'
        ),
        'Test correct secret with good user auth with bad choice'
    );
    expectReject( $res, 500, "Bad result during auth: 9" );

    ok(
        $res = $client->_get(
            '/checkstate',
            accept => 'application/json',
            query  => 'choice=1_demo&secret=x&user=dwho&password=dwho'
        ),
        'Test correct secret with good user auth and good choice'
    );
    $j = expectJSON($res);
    is( $j->{result}, 1, "response has a result key with value 1" );

}

done_testing();

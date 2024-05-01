use warnings;
use Test::More;
use Time::Fake;
use strict;

BEGIN {
    require 't/test-lib.pm';
    use_ok('Lemonldap::NG::Common::Session');
    use_ok('Lemonldap::NG::Portal::Main::Request');
    delete $ENV{LLNG_HASHED_SESSION_STORE};
}

foreach my $hashedSessionStore ( 0 .. 1 ) {

    subtest(
        ( $hashedSessionStore ? 'Hashed session' : 'Unhashed session' ) =>
          sub {
            my $res;
            my $client = LLNG::Manager::Test->new( {
                    ini => { hashedSessionStore => $hashedSessionStore },
                }
            );

            my $portal = $client->p;

            my ( $as, $id, $req );

            ok( (
                    $as =
                      $portal->getApacheSession( undef, info => { aa => 1 } )
                      and $id = $as->id
                ),
                'Get a new session'
            );

            ok(
                -f $portal->conf->{globalStorageOptions}->{Directory} . '/'
                  . ( $hashedSessionStore ? id2storage($id) : $id ),
                'Session name is hashed'
            );

            ok( $as = $portal->getApacheSession($id), 'Recover session' );

            ok( $as->data->{aa} == 1, 'Data is stored' );

            $req = Lemonldap::NG::Portal::Main::Request->new( {
                    'HTTP_ACCEPT'     => 'text/html',
                    'HTTP_USER_AGENT' =>
                      'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
                    'PATH_INFO'            => '/',
                    'REMOTE_ADDR'          => '127.0.0.1',
                    'REQUEST_METHOD'       => 'GET',
                    'REQUEST_URI'          => '/',
                    'SCRIPT_NAME'          => '',
                    'SERVER_NAME'          => 'auth.example.com',
                    'SERVER_PORT'          => '80',
                    'SERVER_PROTOCOL'      => 'HTTP/1.1',
                    'psgi.url_scheme'      => 'http',
                    'psgix.input.buffered' => 0,
                }
            );

            $req->{sessionInfo}->{$_} = $as->data->{$_}
              foreach ( keys %{ $as->data } );

            $as = undef;
            my $now = time;

            Time::Fake->offset( '+' . ( 5 + $hashedSessionStore * 5 ) . 'm' );
            $portal->updateSession( $req, { bb => 2 }, $id );

            $as = undef;

            ok( $as = $portal->getApacheSession($id), 'Recover session' );

            ok( ( $as->data->{aa} == 1 && $as->data->{bb} == 2 ),
                'Data is updated' );

            ok( ($as->data->{_updateTime} - $now) > 500, '_updateTime updated');

            $as = undef;

            ok( $as = $portal->getApacheSession($id), 'Recover session' );

            ok( ( $as->data->{aa} == 1 && $as->data->{bb} == 2 ),
                'Data is updated' );

            done_testing();
        }
    );

}

done_testing();

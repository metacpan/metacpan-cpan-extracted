use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';
my $maintests = 5;

SKIP: {
    eval { require Crypt::U2F::Server; require Authen::U2F::Tester };
    if ( $@ or $Crypt::U2F::Server::VERSION < 0.42 ) {
        skip 'Missing libraries', $maintests;
    }

    use_ok('Lemonldap::NG::Common::FormEncode');
    my $res;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel       => 'error',
                sfOnlyUpgrade  => 1,
                u2fActivation  => 1,
                u2fAuthnLevel  => 5,
                authentication => 'Demo',
                userDB         => 'Same',
                'vhostOptions' => {
                    'test1.example.com' => {
                        'vhostAuthnLevel' => 3
                    },
                },
            }
        }
    );

    # CASE 1: no 2F available
    # -----------------------
    my $query = 'user=rtyler&password=rtyler';
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Auth query'
    );
    my $id = expectCookie($res);

    # After attempting to access test1,
    # the handler sends up back to /upgradesession
    # --------------------------------------------
    ok(
        $res = $client->_get(
            '/upgradesession',
            query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29t',
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Upgrade session query'
    );

    ( my $host, my $url, $query ) =
      expectForm( $res, undef, '/upgradesession', 'confirm', 'url' );

    # Accept session upgrade
    # ----------------------

    ok(
        $res = $client->_post(
            '/upgradesession',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Accept session upgrade query'
    );

    expectCookie( $res, 'lemonldappdata' );

    # A message warns the user that they do not have any 2FA available
    expectPortalError( $res, 103 );

    $query = 'user=rtyler&password=rtyler';
    ok(
        $res = $client->_post(
            '/upgradesession',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Accept session upgrade query'
    );
    expectRedirection( $res, 'http://auth.example.com/' );
    $client->logout($id);
}

count($maintests);
clean_sessions();

done_testing( count() );


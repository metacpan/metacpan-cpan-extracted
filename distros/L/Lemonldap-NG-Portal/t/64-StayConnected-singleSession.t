use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                   => 'error',
            useSafeJail                => 1,
            stayConnected              => '$env->{REMOTE_ADDR} eq "127.0.0.1"',
            loginHistoryEnabled        => 1,
            securedCookie              => 1,
            stayConnectedTimeout       => 1000,
            stayConnectedCookieName    => 'llngpersistent',
            stayConnectedSingleSession => 1,
            portalMainLogo             => 'common/logos/logo_llng_old.png',
            accept                     => 'text/html',
        }
    }
);

sub login_create_persistent_cookie_from_scratch {
    my ($client) = @_;
    my $res;

    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho&stayconnected=1'),
            length => 39
        ),
        'Auth query'
    );
    count(1);
    my $id = expectCookie($res);
    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/registerbrowser', 'fg', 'token' );

    # Push fingerprint
    $query =~ s/fg=/fg=aaa/;
    ok(
        $res = $client->_post(
            '/registerbrowser',
            IO::String->new($query),
            length => length($query),
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Post fingerprint'
    );
    count(1);
    expectRedirection( $res, 'http://auth.example.com/' );
    my $cid = expectCookie( $res, 'llngpersistent' );
    return ( $id, $cid );
}

sub try_connect_with_persistent_cookie {
    my ( $client, $cid ) = @_;
    my $res;
    ok(
        $res = $client->_get(
            '/',
            cookie => "llngpersistent=$cid",
            accept => 'text/html',
        ),
        'Try to auth with persistent cookie'
    );
    count(1);
    expectOK($res);
    if ( $res->[2]->[0] =~ qr/Register browser/ ) {
        my ( $host, $url, $query ) =
          expectForm( $res, '#', undef, 'fg', 'token' );

        # Push fingerprint
        $query =~ s/fg=/fg=aaa/;
        ok(
            $res = $client->_post(
                '/',
                IO::String->new($query),
                cookie => "llngpersistent=$cid",
                length => length($query),
                accept => 'text/html',
            ),
            'Post fingerprint'
        );
        count(1);
        expectRedirection( $res, 'http://auth.example.com/' );
        return expectCookie($res);
    }
    else {
        return;
    }
}

# Create a persistent connection
my ( $id, $cid ) = login_create_persistent_cookie_from_scratch($client);
$id = try_connect_with_persistent_cookie( $client, $cid );
ok( $id, "Got cookie" );
$id = try_connect_with_persistent_cookie( $client, $cid );
ok( $id, "Got cookie" );
count(2);

# Create a second persistent connection
my ( $id2, $cid2 ) = login_create_persistent_cookie_from_scratch($client);
$id2 = try_connect_with_persistent_cookie( $client, $cid2 );
ok( $id2, "Got cookie" );
count(1);

# First persistent cookie should not be valid anymore
$id = try_connect_with_persistent_cookie( $client, $cid );
ok( !$id, "First persistent ID is no longer valid" );
count(1);

clean_sessions();
done_testing( count() );


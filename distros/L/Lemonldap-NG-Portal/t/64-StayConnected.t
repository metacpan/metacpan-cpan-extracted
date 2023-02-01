use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                => 'error',
            useSafeJail             => 1,
            stayConnected           => '$env->{REMOTE_ADDR} eq "127.0.0.1"',
            loginHistoryEnabled     => 1,
            securedCookie           => 1,
            stayConnectedTimeout    => 1000,
            stayConnectedCookieName => 'llngpersistent',
            portalMainLogo          => 'common/logos/logo_llng_old.png',
            accept                  => 'text/html',
        }
    }
);

subtest "Register session, use it, then logout" => sub {
    my $res;
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho&stayconnected=1'),
            length => 39
        ),
        'Auth query'
    );
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
    expectRedirection( $res, 'http://auth.example.com/' );
    my $cid = expectCookie( $res, 'llngpersistent' );
    ok( $res->[1]->[5] =~ /\bsecure\b/, ' Secure cookie found' )
      or explain( $res->[1]->[5], 'Secure cookie found' );

    # Try to connect with persistent connection cookie
    ok(
        $res = $client->_get(
            '/',
            cookie => "llngpersistent=$cid",
            accept => 'text/html',
        ),
        'Try to auth with persistent cookie'
    );
    expectOK($res);
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'fg', 'token' );

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
    expectRedirection( $res, 'http://auth.example.com/' );
    $id = expectCookie($res);

    # Make sure stayconnected session is cleaned up on logout
    my $session = getSession($cid);
    is( $session->{data}->{fingerprint}, 'aaa' );
    $client->logout($id);
    $session = getSession($cid);
    ok( $session->{error}, "Connection session cannot be found" );

    clean_sessions();
};

subtest "Make sure connection ID is saved on first login too" => sub {
    my $res;
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho&stayconnected=1'),
            length => 39
        ),
        'Auth query'
    );
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
    expectRedirection( $res, 'http://auth.example.com/' );
    my $cid = expectCookie( $res, 'llngpersistent' );
    ok( $res->[1]->[5] =~ /\bsecure\b/, ' Secure cookie found' )
      or explain( $res->[1]->[5], 'Secure cookie found' );

    # Make sure stayconnected session is cleaned up on logout
    my $session = getSession($cid);
    is( $session->{data}->{fingerprint}, 'aaa' );
    $client->logout($id);
    $session = getSession($cid);
    ok( $session->{error}, "Connection session cannot be found" );

    clean_sessions();
};

done_testing();


use warnings;
use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                   => 'error',
            stayConnected              => 1,
            singleSession              => 1,
            notifyDeleted              => 1,
            loginHistoryEnabled        => 1,
            securedCookie              => 1,
            stayConnectedTimeout       => 1000,
            stayConnectedSingleSession => 1,
        }
    }
);

sub login_create_persistent_cookie_from_scratch {
    my ( $client, $notifydeleted ) = @_;
    my $res;

    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho&stayconnected=1'),
            length => 39
        ),
        'Auth query'
    );
    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/registerbrowser', 'fg', 'token' );

    # Push fingerprint
    $query =~ s/fg=/fg=aaa/;
    ok(
        $res = $client->_post(
            '/registerbrowser',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post fingerprint'
    );

    my $id = expectCookie($res);
    if ($notifydeleted) {
        like( $res->[2]->[0], qr/sessionsDeleted/, "Show deleted sessions" );
        expectForm( $res, "auth.example.com", "/" );
    }
    else {
        expectRedirection( $res, 'http://auth.example.com/' );
    }
    my $cid = expectCookie( $res, 'llngconnection' );
    return ( $id, $cid );
}

sub sessionid_not_valid {
    my ( $client, $id ) = @_;
    my $res;
    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Check session validity'
    );
    is( getHeader( $res, 'Lm-Remote-User' ),
        undef, "Session ID no longer valid" );
}

sub sessionid_still_valid {
    my ( $client, $id ) = @_;
    my $res;
    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Check session validity'
    );
    expectAuthenticatedAs( $res, "dwho" );
}

sub try_connect_with_persistent_cookie {
    my ( $client, $cid, $notifydeleted ) = @_;
    my $res;
    ok(
        $res = $client->_get(
            '/',
            cookie => "llngconnection=$cid",
            accept => 'text/html',
        ),
        'Try to auth with persistent cookie'
    );
    expectOK($res);
    if ( $res->[2]->[0] =~ qr/id="fg"/ ) {
        my ( $host, $url, $query ) =
          expectForm( $res, '#', undef, 'fg', 'token' );

        # Push fingerprint
        $query =~ s/fg=/fg=aaa/;
        ok(
            $res = $client->_post(
                '/',
                IO::String->new($query),
                cookie => "llngconnection=$cid",
                length => length($query),
                accept => 'text/html',
            ),
            'Post fingerprint'
        );
        if ($notifydeleted) {
            like( $res->[2]->[0], qr/sessionsDeleted/,
                "Show deleted sessions" );
            expectForm( $res, "auth.example.com", "/" );
        }
        else {
            expectRedirection( $res, 'http://auth.example.com/' );
        }
        return expectCookie($res);
    }
    else {
        return;
    }
}

subtest "Login with stay connected, then with persistent cookie"
  . ", user sees notification" => sub {

    clean_sessions();

    # Create a persistent connection
    my ( $id, $cid ) = login_create_persistent_cookie_from_scratch($client);
    sessionid_still_valid( $client, $id );

    # NotifyDeleted must be shown
    my $id2 = try_connect_with_persistent_cookie( $client, $cid, 1 );
    sessionid_still_valid( $client, $id2 );
    sessionid_not_valid( $client, $id );
  };

subtest "Login with stay connected, then without persistent cookie"
  . ", user sees notification" => sub {

    clean_sessions();

    # Create a persistent connection
    my ( $id, $cid ) = login_create_persistent_cookie_from_scratch($client);
    sessionid_still_valid( $client, $id );

    # NotifyDeleted must be shown
    my ( $id2, $cid2 ) =
      login_create_persistent_cookie_from_scratch( $client, 1 );
    sessionid_not_valid( $client, $id );
  };

clean_sessions();
done_testing();


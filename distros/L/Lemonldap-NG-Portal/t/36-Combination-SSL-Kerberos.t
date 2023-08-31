use warnings;
use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
    eval "use GSSAPI";
}

my $res;
my $maintests = 3;
my $client    = client();

my $userdb = tempdb();

SKIP: {
    eval "require GSSAPI";
    if ($@) {
        skip 'GSSAPI not found';
    }

    subtest "Auth by SSL" => sub {

        $res = $client->_get(
            '/',
            accept => "text/html",
            custom => {
                SSL_CLIENT_S_DN_Email => 'dwho',
            }
        );
        my $session = getSession( expectCookie($res) );
        is( $session->data->{_auth}, "SSL", "Correct session auth module" );
        is( $session->data->{_whatToTrace}, "dwho", "Correct session UID" );
    };

    subtest "Auth by Kerberos" => sub {
        $res = $client->_get( '/', accept => 'text/html' );

        expectForm( $res, '#', undef, 'kerberos' );
        ok(
            $res->[2]->[0] =~
              m%<input type="hidden" name="kerberos" value="0" />%,
            'Found hidden attribut "kerberos" with value="0"'
        ) or print STDERR Dumper( $res->[2]->[0] );
        ok( $res->[2]->[0] =~ /kerberos\.(?:min\.)?js/,
            'Get Kerberos javascript' );

        ok( getHtmlElement( $res, '//span[@trspan="waitingmessage"]' ),
            'Found waiting message' );

        my ( $host, $tmp, $query ) =
          expectForm( $res, '#', undef, 'url', 'kerberos', 'ajax_auth_token' );

        # JS code should call /authkrb
        ok(
            $res = $client->_get(
                '/authkrb', accept => 'application/json',
            ),
            'AJAX query'
        );
        is( getHeader( $res, 'WWW-Authenticate' ), 'Negotiate' ),

          ok(
            $res = $client->_get(
                '/authkrb',
                accept => 'application/json',
                custom => { HTTP_AUTHORIZATION => 'Negotiate c29tZXRoaW5n' },
            ),
            'AJAX query'
          );

        my $json = expectJSON($res);
        ok( $json->{ajax_auth_token}, "User token was returned" );
        my $ajax_auth_token = $json->{ajax_auth_token};

        $query =~ s/ajax_auth_token=/ajax_auth_token=$ajax_auth_token/;

        ok(
            $res = $client->_post(
                '/', IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Post form'
        );

        my $session = getSession( expectCookie($res) );
        is( $session->data->{_auth}, "Kerberos",
            "Correct session auth module" );
        is( $session->data->{_whatToTrace}, "dwho", "Correct session UID" );
    };

    subtest "Auth by Demo" => sub {
        $res = $client->_get( '/', accept => 'text/html' );

        ok( getHtmlElement( $res, '//span[@trspan="waitingmessage"]' ),
            'Found waiting message' );

        my ( $host, $tmp, $query ) =
          expectForm( $res, '#', undef, 'url', 'kerberos', 'ajax_auth_token' );

        # Fail Kerberos
        ok(
            $res = $client->_post(
                '/', IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Post form'
        );
        ( $host, $tmp, $query ) =
          expectForm( $res, '#', undef, 'url', 'user', 'password' );

        $query =~ s/user=/user=dwho/;
        $query =~ s/password=/password=dwho/;

        ok(
            $res = $client->_post(
                '/', IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Post form'
        );

        my $session = getSession( expectCookie($res) );
        is( $session->data->{_auth}, "Demo", "Correct session auth module" );
        is( $session->data->{_whatToTrace}, "dwho", "Correct session UID" );
    };
}

clean_sessions();
done_testing();

sub client {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel       => 'error',
                useSafeJail    => 1,
                authentication => 'Combination',
                userDB         => 'Same',
                combination    => '[SSL,Demo] or [Kerberos,Demo] or [Demo]',
                combModules    => {
                    Kerberos => {
                        for  => 1,
                        type => 'Kerberos',
                    },
                    SSL => {
                        for  => 1,
                        type => 'SSL',
                    },
                    Demo => {
                        for  => 0,
                        type => 'Demo',
                    },
                },
                krbKeytab     => '/etc/keytab',
                krbByJs       => 1,
                krbAuthnLevel => 4,
            }
        }
    );
}

# Redefine GSSAPI method for test
no warnings 'redefine';

sub GSSAPI::Context::accept ($$$$$$$$$$) {
    my $a = \@_;
    $a->[4] = bless {}, 'LLNG::GSSR';
    return 1;
}

package LLNG::GSSR;

sub display {
    my $a = \@_;
    $a->[1] = 'dwho@EXAMPLE.COM';
    return 1;
}

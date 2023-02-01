use Test::More;
use IO::String;
use strict;

BEGIN {
    require 't/test-lib.pm';
    eval "use GSSAPI";
}

my $debug = 'error';

SKIP: {
    eval "require GSSAPI";
    if ($@) {
        skip 'GSSAPI not found';
    }
    subtest "Get Negotiate header (no JS)" => sub {
        my $client = LLNG::Manager::Test->new( {
                ini => {
                    logLevel       => $debug,
                    useSafeJail    => 1,
                    authentication => 'Kerberos',
                    userDB         => 'Null',
                    krbKeytab      => '/etc/keytab',
                }
            }
        );
        my $res;
        ok( $res = $client->_get( '/', accept => 'text/html' ),
            'Simple access' );
        ok( $res->[0] == 401, 'Get 401' ) or explain( $res->[0], 401 );
        ok( getHeader( $res, 'WWW-Authenticate' ) eq 'Negotiate',
            'Get negotiate header' )
          or explain( $res->[1], 'WWW-Authenticate => Negotiate' );
    };

    subtest "Ajax flow" => sub {
        &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
        my $client = LLNG::Manager::Test->new( {
                ini => {
                    logLevel       => $debug,
                    useSafeJail    => 1,
                    authentication => 'Kerberos',
                    userDB         => 'Null',
                    krbKeytab      => '/etc/keytab',
                    krbByJs        => 1,
                    krbAuthnLevel  => 4,
                }
            }
        );
        my $res;
        ok(
            $res = $client->_get(
                '/',
                query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tCg==',
                accept => 'text/html'
            ),
            'First access with JS'
        );

        my $pdata = expectCookie( $res, "lemonldappdata" );
        expectForm( $res, '#', undef, 'kerberos' );
        ok(
            $res->[2]->[0] =~
              m%<input type="hidden" name="kerberos" value="0" />%,
            'Found hidden attribut "kerberos" with value="0"'
        ) or print STDERR Dumper( $res->[2]->[0] );
        ok( $res->[2]->[0] =~ /kerberos\.(?:min\.)?js/,
            'Get Kerberos javascript' );

        $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

        my ( $host, $tmp, $query ) =
          expectForm( $res, '#', undef, 'url', 'kerberos', 'ajax_auth_token' );

        # JS code should call /authkrb
        ok(
            $res = $client->_get(
                '/authkrb',
                accept => 'application/json',
                cookie => "$pdata",
            ),
            'AJAX query'
        );
        $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
        is( getHeader( $res, 'WWW-Authenticate' ), 'Negotiate' ),

          ok(
            $res = $client->_get(
                '/authkrb',
                accept => 'application/json',
                cookie => "$pdata",
                custom => { HTTP_AUTHORIZATION => 'Negotiate c29tZXRoaW5n' },
            ),
            'AJAX query'
          );
        $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

        my $json = expectJSON($res);
        ok( $json->{ajax_auth_token}, "User token was returned" );
        my $ajax_auth_token = $json->{ajax_auth_token};

        $query =~ s/ajax_auth_token=/ajax_auth_token=$ajax_auth_token/;

        ok(
            $res = $client->_post(
                '/', IO::String->new($query),
                length => length($query),
                accept => 'text/html',
                cookie => "$pdata",
            ),
            'Post form'
        );

        my $id = expectCookie($res);
        $pdata = expectCookie( $res, "lemonldappdata" );
        ok( !$pdata, "Persistent data removed" );

        # Redirect to application
        ok(
            $res = $client->_get(
                '/',
                query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tCg==&kerberos=0',
                accept => 'text/html',
                cookie => "lemonldap=$id"
            ),
            'Go to portal after authentication'
        );

        expectRedirection( $res, qr#http://test1.example.com# );
        my $cookies = getCookies($res);
        ok(
            !defined( $cookies->{lemonldappdata} ),
            " Make sure no pdata is returned"
        );
    };

    subtest "Test krbAllowedDomains / wrong domain" => sub {
        &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
        my $client = LLNG::Manager::Test->new( {
                ini => {
                    logLevel          => $debug,
                    useSafeJail       => 1,
                    authentication    => 'Kerberos',
                    userDB            => 'Null',
                    krbKeytab         => '/etc/keytab',
                    krbByJs           => 1,
                    krbAuthnLevel     => 4,
                    krbAllowedDomains => 'toto.com titi.com',
                }
            }
        );
        my $res;
        ok(
            $res = $client->_get(
                '/',
                query  => 'kerberos=1',
                accept => 'application/json',
                custom => { HTTP_AUTHORIZATION => 'Negotiate c29tZXRoaW5n' },
            ),
            'Push fake kerberos in blacklisted domain'
        );

        expectReject( $res, 401, 5, "Rejected because the domain is wrong" );
    };

    subtest "Test krbAllowedDomains / correct domain" => sub {
        &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
        my $client = LLNG::Manager::Test->new( {
                ini => {
                    logLevel          => $debug,
                    useSafeJail       => 1,
                    authentication    => 'Kerberos',
                    userDB            => 'Null',
                    krbKeytab         => '/etc/keytab',
                    krbByJs           => 1,
                    krbAuthnLevel     => 4,
                    krbAllowedDomains => 'toto.com example.com',
                }
            }
        );
        my $res;
        ok(
            $res = $client->_get(
                '/',
                query  => 'kerberos=1',
                accept => 'application/json',
                custom => { HTTP_AUTHORIZATION => 'Negotiate c29tZXRoaW5n' },
            ),
            'Push fake kerberos in an allowed domain'
        );
        expectCookie($res);
    };
}

clean_sessions();
done_testing();

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

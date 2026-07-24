use warnings;
use Test::More;
use IO::String;
use URI;
use JSON;
use Lemonldap::NG::Portal::Main::Constants ':all';
use strict;

our $id;

BEGIN {
    require 't/test-lib.pm';
    eval "use GSSAPI";
}

SKIP: {
    eval "require GSSAPI";
    if ($@) {
        skip 'GSSAPI not found';
    }

    # A failed Kerberos attempt must be marked as done (krbDone), so that the
    # javascript does not retry it forever and the user can pick another
    # choice (#3639)
    {
        my $client = LLNG::Manager::Test->new( {
                ini => {
                    authentication      => 'Choice',
                    restSessionServer   => 1,
                    requireToken        => 1,
                    userDB              => 'Same',
                    krbKeytab           => '/etc/keytab',
                    krbByJs             => 1,
                    'authChoiceModules' => {
                        '1_Kerberos' => 'Kerberos;Demo;Null;;;{}',
                        '2_Demo'     => 'Demo;Demo;Null;;;{}'
                    },
                }
            }
        );
        my $res;

        ok(
            $res = $client->_get(
                '/', accept => 'text/html'
            ),
            'Try to login'
        );
        expectPortalError( $res, 9, "Prompted to authenticate" );

        ok( !getJsVars($res)->{krbDone}, "Krb not marked as done" );

        my ( $host, $tmp, $query ) =
          expectForm( $res, '#', undef, 'url', 'kerberos', 'ajax_auth_token' );

        # Fail using invalid Kerberos user (#3639)
        $main::id = 'nobody@example.com';
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
        $query =~ s/lmAuth=\w+/lmAuth=1_Kerberos/;

        ok(
            $res = $client->_post(
                '/', IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Post form'
        );

        # User "nobody" was not found
        expectPortalError( $res, PE_BADCREDENTIALS );

        expectForm( $res, '#', undef, 'url', 'kerberos', 'ajax_auth_token' );

        ok( getJsVars($res)->{krbDone}, "Krb marked as done" );

        # Succeed using known user
        $main::id = 'dwho@example.com';
        ok(
            $res = $client->_get(
                '/authkrb',
                accept => 'application/json',
                custom => { HTTP_AUTHORIZATION => 'Negotiate c29tZXRoaW5n' },
            ),
            'AJAX query'
        );

        $json = expectJSON($res);
        ok( $json->{ajax_auth_token}, "User token was returned" );
        $ajax_auth_token = $json->{ajax_auth_token};

        $query =~ s/ajax_auth_token=[^&]*/ajax_auth_token=$ajax_auth_token/;
        $query =~ s/lmAuth=[^&]*/lmAuth=1_Kerberos/;

        ok(
            $res = $client->_post(
                '/', IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Post form'
        );

        expectCookie($res);
    }

    # A module returning PE_SENDRESPONSE (here Kerberos answering 401 Negotiate
    # with krbByJs=0) leaves _choice in pdata: Auth::Choice only deletes it when
    # the module returns a positive error. That leftover must not override the
    # choice explicitly submitted by the user, otherwise the failed module is
    # retried forever and no other choice can be used (#3641)
    {
        my $client = LLNG::Manager::Test->new( {
                ini => {
                    logLevel          => 'error',
                    authentication    => 'Choice',
                    userDB            => 'Same',
                    krbKeytab         => '/etc/keytab',
                    krbByJs           => 0,
                    authChoiceParam   => 'lmAuth',
                    authChoiceModules => {
                        'kerb' => 'Kerberos;Demo;Demo;;;{}',
                        'demo' => 'Demo;Demo;Demo;;;{}',
                    },
                }
            }
        );
        my $res;

        ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get portal' );
        expectOK($res);

        # Choose Kerberos: it has no ticket, answers 401 and returns
        # PE_SENDRESPONSE, leaving _choice in pdata
        my $query = 'user=&password=&lmAuth=kerb';
        ok(
            $res = $client->_post(
                '/', IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Post Kerberos choice'
        );
        is( $res->[0], 401, 'Kerberos initiates negotiation' );

        my $pdata = getCookies($res)->{lemonldappdata};
        ok( $pdata, 'pdata cookie is set' );

        # Give up on Kerberos and use the other choice instead
        $query = 'user=dwho&password=dwho&lmAuth=demo';
        ok(
            $res = $client->_post(
                '/',
                IO::String->new($query),
                length => length($query),
                accept => 'text/html',
                cookie => "lemonldappdata=$pdata",
            ),
            'Post Demo choice with Kerberos left in pdata'
        );

        my $sessionId = expectCookie($res);
        ok( $sessionId, 'Submitted choice wins over the one left in pdata' );

        $client->logout($sessionId);
    }
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
    $a->[1] = $main::id;
    return 1;
}

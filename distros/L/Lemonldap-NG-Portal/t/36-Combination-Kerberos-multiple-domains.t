use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
    eval "use GSSAPI";
}

my $res;
my $client;

my $userdb = tempdb();

SKIP: {
    eval { require GSSAPI; require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found';
    }
    if ($@) {
        skip "dependencies not found: $@";
    }

    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");
    $dbh->do('CREATE TABLE users_dom1 (user text,password text,name text)');
    $dbh->do('CREATE TABLE users_dom2 (user text,password text,name text)');
    $dbh->do(
        "INSERT INTO users_dom1 VALUES ('hford','harrison','Harrison Ford')");
    $dbh->do("INSERT INTO users_dom2 VALUES ('hford','henry','Henry Ford')");

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel       => 'error',
                useSafeJail    => 1,
                authentication => 'Combination',
                userDB         => 'Same',

                combination => '[K1,D1] or [K2,D2] or [D1] or [D2]',
                combModules => {
                    K1 => {
                        for  => 1,
                        type => 'Kerberos',
                        over => {
                            krbAllowedDomains => 'actors.com',
                        }
                    },
                    K2 => {
                        for  => 1,
                        type => 'Kerberos',
                        over => {
                            krbAllowedDomains => 'car.com',
                        }
                    },
                    D1 => {
                        for  => 0,
                        type => 'DBI',
                        over => {
                            dbiAuthTable => 'users_dom1',
                        },
                    },
                    D2 => {
                        for  => 0,
                        type => 'DBI',
                        over => {
                            dbiAuthTable => 'users_dom2',
                        },
                    },
                },
                restSessionServer   => 1,
                krbRemoveDomain     => 1,
                krbKeytab           => '/etc/keytab',
                krbByJs             => 1,
                dbiAuthChain        => "dbi:SQLite:dbname=$userdb",
                dbiAuthUser         => '',
                dbiAuthPassword     => '',
                dbiAuthLoginCol     => 'user',
                dbiAuthPasswordCol  => 'password',
                dbiAuthPasswordHash => '',
                dbiExportedVars     => { cn => 'name', uid => 'user' },
            }
        }
    );

    subtest "Successful Kerberos authentication on dom1" => sub {
        $ENV{krb_user} = 'hford@actors.com';

        ok( $res = $client->_get( '/', accept => 'text/html' ),
            'Simple access' );
        ok( $res->[2]->[0] =~ /script.*kerberos\.js/s, 'Found Kerberos JS' )
          or explain( $res->[2]->[0], 'script.*kerberos.js' );
        my ( $host, $tmp, $query ) =
          expectForm( $res, '#', undef, 'kerberos', 'ajax_auth_token' );

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
        my $id = expectCookie($res);
        expectSessionAttributes( $client, $id, cn => 'Harrison Ford' );
    };

    subtest "Successful Kerberos authentication on dom2" => sub {
        $ENV{krb_user} = 'hford@car.com';
        ok( $res = $client->_get( '/', accept => 'text/html' ),
            'Simple access' );
        ok( $res->[2]->[0] =~ /script.*kerberos\.js/s, 'Found Kerberos JS' )
          or explain( $res->[2]->[0], 'script.*kerberos.js' );
        my ( $host, $tmp, $query ) =
          expectForm( $res, '#', undef, 'kerberos', 'ajax_auth_token' );

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
        my $id = expectCookie($res);
        expectSessionAttributes( $client, $id, cn => 'Henry Ford' );
    };

    subtest "Fallback to Dom1" => sub {
        ok( $res = $client->_get( '/', accept => 'text/html' ),
            'Simple access' );
        ok( $res->[2]->[0] =~ /script.*kerberos\.js/s, 'Found Kerberos JS' )
          or explain( $res->[2]->[0], 'script.*kerberos.js' );
        my ( $host, $tmp, $query ) =
          expectForm( $res, '#', undef, 'kerberos', 'ajax_auth_token' );

        # JS code fails to obtain ajax_auth_token for some reason
        ok(
            $res = $client->_post(
                '/', IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Post form'
        );
        my ( $host, $tmp, $query ) =
          expectForm( $res, '#', undef, 'user', 'password' );
        $query =~ s/user=/user=hford/;
        $query =~ s/password=/password=harrison/;
        ok(
            $res = $client->_post(
                '/', IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Post form'
        );
        my $id = expectCookie($res);
        expectSessionAttributes( $client, $id, cn => 'Harrison Ford' );
    };

    subtest "Fallback to Dom2" => sub {
        ok( $res = $client->_get( '/', accept => 'text/html' ),
            'Simple access' );
        ok( $res->[2]->[0] =~ /script.*kerberos\.js/s, 'Found Kerberos JS' )
          or explain( $res->[2]->[0], 'script.*kerberos.js' );
        my ( $host, $tmp, $query ) =
          expectForm( $res, '#', undef, 'kerberos', 'ajax_auth_token' );

        # JS code fails to obtain ajax_auth_token for some reason
        ok(
            $res = $client->_post(
                '/', IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Post form'
        );
        my ( $host, $tmp, $query ) =
          expectForm( $res, '#', undef, 'user', 'password' );
        $query =~ s/user=/user=hford/;
        $query =~ s/password=/password=henry/;
        ok(
            $res = $client->_post(
                '/', IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Post form'
        );
        my $id = expectCookie($res);
        expectSessionAttributes( $client, $id, cn => 'Henry Ford' );
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
    $a->[1] = $ENV{'krb_user'};
    return 1;
}


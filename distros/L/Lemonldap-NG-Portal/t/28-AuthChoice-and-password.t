use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $maintests = 10;

eval { unlink 't/userdb.db' };

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }
    skip 'LLNGTESTLDAP is not set', $maintests unless ( $ENV{LLNGTESTLDAP} );
    require 't/test-ldap.pm';
    my $dbh = DBI->connect("dbi:SQLite:dbname=t/userdb.db");
    $dbh->do('CREATE TABLE users (user text,password text,name text)');
    $dbh->do("INSERT INTO users VALUES ('dwho','dwho','Doctor who')");

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                 => 'error',
                useSafeJail              => 1,
                authentication           => 'Choice',
                userDB                   => 'Same',
                passwordDB               => 'Choice',
                portalRequireOldPassword => 1,

                authChoiceParam   => 'test',
                authChoiceModules => {
                    ldap => 'LDAP;LDAP;LDAP',
                    sql  => 'DBI;DBI;DBI',
                },

                dbiAuthChain        => 'dbi:SQLite:dbname=t/userdb.db',
                dbiAuthUser         => '',
                dbiAuthPassword     => '',
                dbiAuthTable        => 'users',
                dbiAuthLoginCol     => 'user',
                dbiAuthPasswordCol  => 'password',
                dbiAuthPasswordHash => '',

                ldapServer      => 'ldap://127.0.0.1:19389/',
                ldapBase        => 'ou=users,dc=example,dc=com',
                managerDn       => 'cn=admin,dc=example,dc=com',
                managerPassword => 'admin',
            }
        }
    );

    # Test LDAP and SQL
    foreach my $postString (
        'user=dwho&password=dwho&test=ldap',
        'user=dwho&password=dwho&test=sql'
      )
    {

        # Try yo authenticate
        # -------------------
        ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get menu' );
        my @form = ( $res->[2]->[0] =~ m#<form.*?</form>#sg );
        ok( @form == 2, 'Display 2 choices' );
        foreach (@form) {
            expectForm( [ $res->[0], $res->[1], [$_] ], undef, undef, 'test' );
        }
        ok(
            $res = $client->_post(
                '/', IO::String->new($postString),
                length => length($postString),
                accept => 'text/html',
            ),
            'Auth query'
        );
        my $id = expectCookie($res);

        ok(
            $res = $client->_post(
                '/',
                IO::String->new(
                    'oldpassword=dwho&newpassword=test&confirmpassword=test'),
                cookie => "lemonldap=$id",
                accept => 'application/json',
                length => 54
            ),
            'Change password'
        );
        expectOK($res);
        $client->logout($id);
        my $tmp = $postString;
        $tmp =~ s/password=dwho/password=test/;
        ok(
            $res = $client->_post(
                '/',
                IO::String->new($tmp),
                length => length($tmp),
            ),
            'Auth query with new password'
        );
        expectOK($res);
        $id = expectCookie($res);

        $client->logout($id);
    }

    clean_sessions();
}
count($maintests);
eval { unlink 't/userdb.db' };
stopLdapServer() if $ENV{LLNGTESTLDAP};
clean_sessions();
done_testing( count() );

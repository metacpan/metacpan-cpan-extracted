use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $maintests = 4;

SKIP: {
    skip 'LLNGTESTLDAP is not set', $maintests unless ( $ENV{LLNGTESTLDAP} );
    require 't/test-ldap.pm';

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                 => 'error',
                useSafeJail              => 1,
                authentication           => 'LDAP',
                portal                   => 'http://auth.example.com/',
                userDB                   => 'Same',
                passwordDB               => 'LDAP',
                portalRequireOldPassword => '$uid eq "dwho"',
                ldapServer               => $main::slapd_url,
                ldapBase                 => 'ou=users,dc=example,dc=com',
                managerDn                => 'cn=admin,dc=example,dc=com',
                managerPassword          => 'admin',
            }
        }
    );
    my $postString = 'user='
      . ( $ENV{LDAPACCOUNT} || 'dwho' )
      . '&password='
      . ( $ENV{LDAPPWD} || 'dwho' );

    # Try to authenticate with
    # the server temporarily offline (#2018)
    # --------------------------------------
    stopLdapServer();
    ok(
        $res = $client->_post(
            '/', IO::String->new($postString),
            length => length($postString)
        ),
        'Auth query'
    );

    expectReject( $res, 401, 6 );

    # Try to authenticate with the
    # server back online
    # ----------------------------
    startLdapServer();
    ok(
        $res = $client->_post(
            '/', IO::String->new($postString),
            length => length($postString)
        ),
        'Auth query'
    );
    expectOK($res);
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
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=test'),
            cookie => "lemonldap=$id",
            length => 23
        ),
        'Auth query with new password'
    );
    expectOK($res);
    $id = expectCookie($res);

    $client->logout($id);
}
count($maintests);
clean_sessions();
done_testing( count() );

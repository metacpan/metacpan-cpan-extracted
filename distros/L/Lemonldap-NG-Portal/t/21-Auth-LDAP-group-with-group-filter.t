use warnings;
use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $maintests = 5;

no warnings 'once';

SKIP: {
    skip 'LLNGTESTLDAP is not set', $maintests unless ( $ENV{LLNGTESTLDAP} );
    require 't/test-ldap.pm';

    my $client = LLNG::Manager::Test->new(
        {
            ini => {
                logLevel                 => 'error',
                useSafeJail              => 1,
                authentication           => 'LDAP',
                portal                   => 'http://auth.example.com/',
                userDB                   => 'Same',
                passwordDB               => 'LDAP',
                portalRequireOldPassword => 1,
                ldapServer               => $main::slapd_url,
                ldapBase                 => 'ou=users,dc=example,dc=com',
                ldapGroupBase            => 'ou=groups,dc=example,dc=com',
                groupLDAPFilter          => '(|(objectClass=extensibleObject)(objectClass=groupOfNames))',
                ldapGroupAttributeName   => 'member',
                managerDn                => 'cn=admin,dc=example,dc=com',
                managerPassword          => 'admin',
                restSessionServer        => 1,
            }
        }
    );

    # Try to authenticate
    # -------------------

    ok(
        $res = $client->_post(
            '/', IO::String->new('user=dwho&password=dwho'),
            length => 23
        ),
        'Auth query'
    );
    expectOK($res);
    my $id = expectCookie($res);

    ok( $res = $client->_get("/sessions/global/$id"), 'Get UTF-8' );
    expectOK($res);
    ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
      or print STDERR $@;
    ok( defined $res->{hGroups}->{extgroup}, 'Group extgroup found in session');
    ok( defined $res->{hGroups}->{mygroup}, 'Group mygroup found in session');

}

count($maintests);
clean_sessions();
done_testing( count() );

use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $maintests = 8;

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
                portalRequireOldPassword => 1,
                ldapServer               => 'ldap://127.0.0.1:19389/',
                ldapBase                 => 'ou=users,dc=example,dc=com',
                managerDn                => 'cn=admin,dc=example,dc=com',
                managerPassword          => 'admin',
                restSessionServer        => 1,
                ldapExportedVars         => {
                    cn => 'cn',
                },
            }
        }
    );
    my $postString = 'user='
      . ( $ENV{LDAPACCOUNT} || 'dwho' )
      . '&password='
      . ( $ENV{LDAPPWD} || 'dwho' );

    # Try yo authenticate
    # -------------------

    # 1- Characters available in ISO and UTF-8
    ok(
        $res = $client->_post(
            '/', IO::String->new('user=french&password=french'),
            length => 27
        ),
        'Auth query'
    );
    expectOK($res);
    my $id = expectCookie($res);

    ok( $res = $client->_get("/sessions/global/$id"), 'Get UTF-8' );
    expectOK($res);
    ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
      or print STDERR $@;
    ok( $res->{cn} eq 'Frédéric Accents', 'UTF-8 values' )
      or explain( $res, 'cn => Frédéric Accents' );

    # 2- Characters UTF-8 only
    ok(
        $res = $client->_post(
            '/', IO::String->new('user=russian&password=russian'),
            length => 29
        ),
        'Auth query'
    );
    expectOK($res);
    $id = expectCookie($res);

    ok( $res = $client->_get("/sessions/global/$id"), 'Get UTF-8' );
    expectOK($res);
    ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
      or print STDERR $@;
    ok( $res->{cn} eq 'Русский', 'UTF-8 values' )
      or explain( $res, 'cn => Русский' );

    clean_sessions();
}
count($maintests);
stopLdapServer() if $ENV{LLNGTESTLDAP};
done_testing( count() );

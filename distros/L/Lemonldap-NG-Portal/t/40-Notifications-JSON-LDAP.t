use Test::More;
use strict;
use IO::String;
use Lemonldap::NG::Common::Notifications::LDAP "JSON";
use Lemonldap::NG::Common::Logger::Std;

my $res;
my $notif;
my $maintests = 11;
my $logLevel  = 'error';
require 't/test-lib.pm';
my $file                       = tempdb();
my $ldapBindDN                 = 'cn=admin,dc=example,dc=com';
my $ldapBindPassword           = 'admin';
my $ldapConfBase               = 'ou=notifications,dc=example,dc=com';
my $notificationStorageOptions = {
    conf   => {},
    logger =>
      Lemonldap::NG::Common::Logger::Std->new( { logLevel => $logLevel } ),
    userLogger =>
      Lemonldap::NG::Common::Logger::Std->new( { logLevel => $logLevel } ),
    ldapBindDN       => $ldapBindDN,
    ldapBindPassword => $ldapBindPassword,
    ldapConfBase     => $ldapConfBase,
};

SKIP: {
    skip 'LLNGTESTLDAP is not set', $maintests unless ( $ENV{LLNGTESTLDAP} );
    require 't/test-ldap.pm';
    $notificationStorageOptions->{ldapServer} = $main::slapd_url;
    use Net::LDAP;
    $notif = Lemonldap::NG::Common::Notifications::LDAP->new(
        $notificationStorageOptions);
    my $ldap = Net::LDAP->new($main::slapd_url);
    my $mesg = $ldap->bind( $ldapBindDN, password => $ldapBindPassword );
    is( $mesg->code, 0, "Bind to LDAP server" ) or diag $mesg->error;

    my $result = $ldap->add(
        'ou=notifications,dc=example,dc=com',
        attrs => [
            ou          => 'notifications',
            objectClass => 'organizationalUnit'
        ]
    );
    is( $result->code, 0, "Add branch" ) or diag $result->error;

    my $xml = '
    {
    "uid": "dwho",
    "date": "2016-05-30",
    "reference": "testref",
    "title": "Test title",
    "subtitle": "Test subtitle",
    "text": "This is a test text",
    "check": "Accept test"
    }';
    $notif->newNotification($xml);

    $xml = '
{
  "uid": "dwho",
  "date": "2016-05-29",
  "reference": "testref2",
  "condition": "$env->{REMOTE_ADDR} =~ /127.0.0.1/",
  "title": "Test2 title",
  "subtitle": "Test2 subtitle",
  "text": "This is a second test text",
  "check": ["Accept test","I am sure"]
}';
    $notif->newNotification($xml);

    $xml = '
{
  "uid": "dwho",
  "date": "2050-05-30",
  "reference": "testref3",
  "condition": "\'0\'",
  "title": "Test title",
  "subtitle": "Test subtitle",
  "text": "This is a test text",
  "check": ["Accept test"]
}';
    $notif->newNotification($xml);

    $xml = '
{
  "uid": "rtyler",
  "date": "2016-05-29",
  "reference": "testref",
  "condition": "$env->{REMOTE_ADDR} =~ /127.1.1.1/",
  "title": "Test title",
  "subtitle": "Test subtitle",
  "text": "This is a test text",
  "check": ["Accept test"]
}';
    $notif->newNotification($xml);

    $xml = '
{
  "uid": "rtyler",
  "date": "2050-05-16",
  "reference": "testref2",
  "title": "Test title",
  "subtitle": "Test subtitle",
  "text": "This is a test text",
  "check": ["Accept test"]
}';
    $notif->newNotification($xml);

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $logLevel,
                useSafeJail                => 1,
                notification               => 1,
                notificationStorage        => 'LDAP',
                notificationStorageOptions => $notificationStorageOptions,
                oldNotifFormat             => 0,
            }
        }
    );

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new(
'user=dwho&password=dwho&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw=='
            ),
            accept => 'text/html',
            length => 64,
        ),
        'Auth query'
    );
    expectOK($res);
    my $id   = expectCookie($res);
    my @refs = ( $res->[2]->[0] =~
          m#<input type="hidden" name="reference[\dx]+" value="(\w+?)"/>#gs );
    ok( @refs == 2, 'Two notification references found' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $refs[0] eq 'testref2', '1st reference found is "testref2"' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $refs[1] eq 'testref', '2nd reference found is "testref"' )
      or print STDERR Dumper( $res->[2]->[0] );
    expectForm( $res, undef, '/notifback', 'reference1x1', 'url' );

    # Verify that cookie is ciphered (session invalid)
    ok(
        $res = $client->_get(
            '/',
            query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==',
            cookie => "lemonldap=$id",
        ),
        'Test cookie received'
    );
    expectReject($res);

    # Try to validate notification without accepting it
    my $str = 'reference1x1=testref&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==';
    ok(
        $res = $client->_post(
            '/notifback',
            IO::String->new($str),
            cookie => "lemonldap=$id",
            accept => 'text/html',
            length => length($str),
        ),
        "Don't accept notification"
    );
    expectOK($res);

    # Try to validate notifications
    $str =
'reference1x1=testref&check1x1x1=accepted&reference1x2=testref2&check1x2x1=accepted&check1x2x2=accepted&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==';
    ok(
        $res = $client->_post(
            '/notifback',
            IO::String->new($str),
            cookie => "lemonldap=$id",
            accept => 'text/html',
            length => length($str),
        ),
        "Accept notifications"
    );
    expectRedirection( $res, 'http://test1.example.com/' );
    my $cookies = getCookies($res);
    ok(
        !defined( $cookies->{lemonldappdata} ),
        " Make sure no pdata is returned"
    );
    $client->logout($id);

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new(
'user=rtyler&password=rtyler&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw=='
            ),
            accept => 'text/html',
            length => 68,
        ),
        'Auth query'
    );
    expectRedirection( $res, 'http://test1.example.com/' );
    $id = expectCookie($res);
    $client->logout($id);

    eval { unlink $file };
    clean_sessions();
}

count($maintests);
done_testing( count() );


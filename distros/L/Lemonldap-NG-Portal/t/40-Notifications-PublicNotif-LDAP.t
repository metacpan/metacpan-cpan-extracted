use warnings;
use Test::More;
use strict;
use IO::String;
use Lemonldap::NG::Common::Notifications::LDAP "JSON";
use Lemonldap::NG::Common::Logger::Std;

my $res;
my $notif;
my $maintests = 5;
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
    "uid": "public-warn",
    "date": "2016-05-30",
    "reference": "testref",
    "title": "Test title",
    "subtitle": "Test subtitle",
    "text": "This is a test text"
    }';
    $notif->newNotification($xml);

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $logLevel,
                useSafeJail                => 1,
                notification               => 1,
                publicNotifications        => 1,
                oldNotifFormat             => 0,
                notificationStorage        => 'LDAP',
                notificationStorageOptions => $notificationStorageOptions,
                oldNotifFormat             => 0,
            }
        }
    );

    # Display login page with public notifications
    # --------------------------------------------
    ok(
        $res = $client->_get(
            '/', accept => 'text/html',
        ),
        'Access login page with public notifications'
    );
    ok( $res->[2]->[0] =~ m%public-warn%, 'Notification warn displayed' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%<script type="text/javascript" src="/static/common/js/carousel\.min\.js\?v=.+?"></script>%, 'Carousel min JS found' )
      or print STDERR Dumper( $res->[2]->[0] );
    eval { unlink $file };
}

count($maintests);
done_testing( count() );


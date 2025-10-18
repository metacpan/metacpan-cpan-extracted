use warnings;
use Test::More;
use strict;
use IO::String;
use JSON;

require 't/test-lib.pm';

my $res;
my $json;
my $file = "$main::tmpDir/20160530_public-info_dGVzdHJlZg==.json";

open F, "> $file" or die($!);
print F '[
{
  "uid": "public-info",
  "date": "2016-05-30",
  "reference": "testref",
  "title": "Test title",
  "subtitle": "Test subtitle",
  "text": "This is a test text for $uid"
}
]';
close F;

my $client = LLNG::Manager::Test->new(
    {
        ini => {
            logLevel                   => 'error',
            useSafeJail                => 1,
            notification               => 1,
            publicNotifications        => 1,
            notificationStorage        => 'File',
            notificationStorageOptions => { dirName => $main::tmpDir },
            oldNotifFormat             => 0,
            portalMainLogo             => 'common/logos/logo_llng_old.png',
        }
    }
);
use Lemonldap::NG::Portal::Main::Constants 'PE_NOTIFICATION';

# Display login page with public notifications
# -------------------
ok(
    $res = $client->_get(
        '/', accept => 'text/html',
    ),
    'Access login page with public notifications'
);
ok( $res->[2]->[0] =~ qr%Test title%, 'Notification displayed' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

# Display login page with public notifications after bad auth
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    'Bad Auth query'
);
ok( $res->[2]->[0] =~ qr%Test title%, 'Notification displayed' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

clean_sessions();

# Display login page without public notifications
# -------------------
unlink $file;

ok(
    $res = $client->_get(
        '/', accept => 'text/html'
    ),
    'Access login page without public notifications'
);
ok( $res->[2]->[0] !~ qr%Test title%, 'Notification not displayed' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

clean_sessions();
done_testing( count() );

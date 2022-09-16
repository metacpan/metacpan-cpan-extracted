use Test::More;
use strict;
use IO::String;
use JSON;

require 't/test-lib.pm';

my $res;
my $json;
my $file = "$main::tmpDir/20160530_dwho_dGVzdHJlZg==.json";

open F, "> $file" or die($!);
print F '[
{
  "uid": "dwho",
  "date": "2016-05-30",
  "reference": "testref",
  "title": "Test title",
  "subtitle": "Test subtitle",
  "text": "This is a test text",
  "check": ["Accept test","Accept test2"]
}
]';
close F;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                   => 'error',
            useSafeJail                => 1,
            notification               => 1,
            notificationStorage        => 'File',
            notificationStorageOptions => { dirName => $main::tmpDir },
            oldNotifFormat             => 0,
            portalMainLogo             => 'common/logos/logo_llng_old.png',
        }
    }
);
use Lemonldap::NG::Portal::Main::Constants 'PE_NOTIFICATION';

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'user=dwho&password=dwho&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw=='),
        length => 64,
    ),
    'Auth query (JSON required)'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{result} == 0, ' Good result' )
  or explain( $json, 'result => 0' );
ok( $json->{error} == PE_NOTIFICATION, ' Notificationtion is pending' )
  or explain( $json, 'error => 36' );
my $id = $json->{ciphered_id};

# Verify that cookie can be deciphered (ciphered_id is valid)
ok(
    $res = $client->_get(
        '/notifback',
        accept => 'text/html',
        cookie => "lemonldap=$id"
    ),
    'Test received Id'
);
count(5);
expectForm( $res, undef, '/notifback', 'reference1x1', 'url' );

ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'user=dwho&password=dwho&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw=='),
        accept => 'text/html',
        length => 64,
    ),
    'Auth query'
);
count(1);
expectOK($res);
$id = expectCookie($res);
expectForm( $res, undef, '/notifback', 'reference1x1', 'url' );

# Verify that cookie is ciphered (session invalid)
ok(
    $res = $client->_get(
        '/',
        query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==',
        cookie => "lemonldap=$id",
    ),
    'Test received cookie'
);
count(1);
expectReject($res);

# Try to cancel notification
ok(
    $res = $client->_get(
        '/notifback',
        query  => "cancel=1",
        cookie => "lemonldap=$id",
        length => 64,
        accept => 'text/html',
    ),
    "Cancel notification"
);

my $c = getCookies($res);
ok( not( $c->{'lemonldap'} ), 'Cookie expired' ) or print STDERR Dumper($c);
count(2);
expectRedirection( $res, 'http://auth.example.com/' );

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'user=dwho&password=dwho&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw=='),
        accept => 'text/html',
        length => 64,
    ),
    'Auth query'
);
count(1);
expectOK($res);
$id = expectCookie($res);
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
count(1);
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
ok( $res->[2]->[0] =~ qr%<h2 class="notifText">Test title</h2>%,
    'Notification displayed' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

ok( $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
    'Found custom Main Logo' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);

# Try to validate notification without accepting it
$str = 'reference1x1=testref&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==';
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
ok( $res->[2]->[0] =~ qr%<h2 class="notifText">Test title</h2>%,
    'Notification displayed' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

# Try to validate notification without accepting it
$str = 'reference1x1=testref&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==';
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
ok( $res->[2]->[0] =~ qr%<h2 class="notifText">Test title</h2>%,
    'Notification displayed' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

# Try to validate notification with accepting just one checkbox
$str =
'reference1x1=testref&check1x1x1=accepted&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==';
ok(
    $res = $client->_post(
        '/notifback',
        IO::String->new($str),
        cookie => "lemonldap=$id",
        accept => 'text/html',
        length => length($str),
    ),
    "Don't accept notification - Accept just one checkbox"
);
ok( $res->[2]->[0] =~ qr%<h2 class="notifText">Test title</h2>%,
    'Notification displayed' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

# Try to validate notification with accepting all checkboxes
$str =
'reference1x1=testref&check1x1x1=accepted&check1x1x2=accepted&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==';
ok(
    $res = $client->_post(
        '/notifback',
        IO::String->new($str),
        cookie => "lemonldap=$id",
        accept => 'text/html',
        length => length($str),
    ),
    "Accept notification"
);
expectRedirection( $res, qr/./ );
$file =~ s/json$/done/;
ok( -e $file, 'Notification was deleted' );
count(2);

$id = expectCookie($res);

ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html',
    ),
    'New auth query'
);
expectAuthenticatedAs( $res, 'dwho' );
ok( $res->[2]->[0] =~ /yourApp/s, 'Menu displayed' );
count(2);

clean_sessions();

unlink $file;

done_testing( count() );

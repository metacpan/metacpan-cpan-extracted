use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
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
  "check": ["Accept test"]
}
]';
close F;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                   => 'error',
            useSafeJail                => 1,
            notification               => 1,
            notificationStorage        => 'File',
            notificationStorageOptions => {
                dirName => $main::tmpDir
            },
            oldNotifFormat => 0,
            requireToken   => 1,
        }
    }
);

# Try to authenticate
# -------------------
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Unauth request' );
count(1);

my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
$query =~
s/.*\b(token=[^&]+).*/$1&user=dwho&password=dwho&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==/;

ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);
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

# Try to validate notification
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
    "Accept notification"
);
expectRedirection( $res, qr/./ );
$file =~ s/json$/done/;
ok( -e $file, 'Notification was deleted' );
count(2);

#print STDERR Dumper($res);

clean_sessions();

unlink $file;

done_testing( count() );

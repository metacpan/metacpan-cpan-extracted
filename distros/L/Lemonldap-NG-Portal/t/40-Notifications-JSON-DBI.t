use Test::More;
use strict;
use IO::String;
use JSON qw(from_json);

my $res;
my $maintests = 17;
require 't/test-lib.pm';
my $file = tempdb();

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }

    my $dbh = DBI->connect("dbi:SQLite:dbname=$file");
    $dbh->do(
'CREATE TABLE notifications (uid text,ref text,date datetime,xml text,cond text,done datetime)'
    );
    $dbh->prepare(
q{INSERT INTO notifications VALUES ('dwho','testref','2016-05-30 00:00:00',?,null,null)}
    )->execute(
        '[
{
  "uid": "dwho",
  "date": "2016-05-30",
  "reference": "testref",
  "title": "Test title",
  "subtitle": "Test subtitle",
  "text": "This is a test text",
  "check": "Accept test"
}
]'
    );
    $dbh->prepare(
q{INSERT INTO notifications VALUES ('dwho','testref2','2016-05-30 00:00:00',?,null,null)}
    )->execute(
        '[
{
  "uid": "dwho",
  "date": "2016-05-29",
  "reference": "testref2",
  "condition": "$env->{REMOTE_ADDR} =~ /127.0.0.1/",
  "title": "Test2 title",
  "subtitle": "Test2 subtitle",
  "text": "This is a second test text",
  "check": ["Accept test","I am sure"]
}
]'
    );
    $dbh->prepare(
q{INSERT INTO notifications VALUES ('dwho','testref3','2050-05-30 00:00:00',?,null,null)}
    )->execute(
        '[
{
  "uid": "dwho",
  "date": "2050-05-30",
  "reference": "testref3",
  "condition": "\'0\'",
  "title": "Test title",
  "subtitle": "Test subtitle",
  "text": "This is a test text",
  "check": ["Accept test"]
}
]'
    );
    $dbh->prepare(
q{INSERT INTO notifications VALUES ('rtyler','testref','2016-05-30 00:00:00',?,null,null)}
    )->execute(
        '[
{
  "uid": "rtyler",
  "date": "2016-05-29",
  "reference": "testref",
  "condition": "$env->{REMOTE_ADDR} =~ /127.1.1.1/",
  "title": "Test title",
  "subtitle": "Test subtitle",
  "text": "This is a test text",
  "check": ["Accept test"]
}
]'
    );
    $dbh->prepare(
q{INSERT INTO notifications VALUES ('rtyler','testref2','2050-05-30 00:00:00',?,null,null)}
    )->execute(
        '[
{
  "uid": "rtyler",
  "date": "2050-05-16",
  "reference": "testref2",
  "title": "Test title",
  "subtitle": "Test subtitle",
  "text": "This is a test text",
  "check": ["Accept test"]
}
]'
    );

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => 'error',
                useSafeJail                => 1,
                notification               => 1,
                notificationStorage        => 'DBI',
                notificationStorageOptions => {
                    dbiChain => "dbi:SQLite:dbname=$file",
                },
                oldNotifFormat        => 0,
                notificationsExplorer => 1
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
          /<input type="hidden" name="reference[\dx]+" value="(\w+?)"\/>/gs );
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
    $id = expectCookie($res);

    # Verify that notification was tagged as 'done'
    my $sth =
      $dbh->prepare('SELECT * FROM notifications WHERE done IS NOT NULL');
    $sth->execute;
    my $i = 0;
    while ( $sth->fetchrow_hashref ) { $i++ }
    ok( $i == 2, 'Notification was deleted' );

    # GET notifications explorer
    ok(
        $res = $client->_get(
            '/mynotifications', cookie => "lemonldap=$id",
        ),
        'Notifications explorer query'
    );

    my $json;
    ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    ok( $json->{result} == 2, ' Result is 2' )
      or explain( $json, "result => 2" );
    ok( $json->{MSG} == 'myNotifications', ' MSG is myNotifications' )
      or explain( $json, "result => 2" );
    ok( $json->{NOTIFICATIONS}->[0]->{reference} =~ /testref2?/,
        ' Notification 1 found' )
      or explain( $json, "Notification 1" );
    ok( $json->{NOTIFICATIONS}->[0]->{reference} =~ /testref2?/,
        ' Notification 2 found' )
      or explain( $json, "Notification 2" );
    ok( $json->{NOTIFICATIONS}->[0]->{epoch} =~ /\d{10}/, ' epoch found' )
      or explain( $json, "Epoch found" );

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

    clean_sessions();
    eval { unlink $file };
}

count($maintests);
done_testing( count() );


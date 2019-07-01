use Test::More;
use strict;
use IO::String;

my $res;
my $file      = 't/notifications.db';
my $maintests = 6;
eval { unlink $file };
require 't/test-lib.pm';

SKIP: {
    eval {
        require DBI;
        require DBD::SQLite;
        require XML::LibXML;
        require XML::LibXSLT;
    };
    if ($@) {
        skip 'DBD::SQLite or XML::Lib* not found', $maintests;
    }

    my $dbh = DBI->connect("dbi:SQLite:dbname=$file");
    $dbh->do(
'CREATE TABLE notifications (uid text,ref text,date datetime,xml text,cond text,done datetime)'
    );
    $dbh->do(
qq{INSERT INTO notifications VALUES ('dwho','testref','2016-05-30 00:00:00','<?xml version="1.0" encoding="UTF-8"?>
<root><notification uid="dwho" date="2016-05-30" reference="testref">
<title>Test title</title>
<subtitle>Test subtitle</subtitle>
<text>This is a test text</text>
<check>Accept test</check>
</notification></root>',null,null)}
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
                oldNotifFormat => 1,
            }
        }
    );

    # Try yo authenticate
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
    my $id = expectCookie($res);
    ok( $res->[2]->[0] =~ /1x1x1/, ' Found ref' );
    expectForm( $res, undef, '/notifback', 'reference1x1', 'url' );

    # Verify that cookie is ciphered (session unvalid)
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
    expectRedirection( $res, 'http://test1.example.com/' );

    # Verify that notification was tagged as 'done'
    my $sth =
      $dbh->prepare('SELECT * FROM notifications WHERE done IS NOT NULL');
    $sth->execute;
    my $i = 0;
    while ( $sth->fetchrow_hashref ) { $i++ }
    ok( $i == 1, 'Notification was deleted' );

    clean_sessions();

    eval { unlink $file };

}

count($maintests);
done_testing( count() );


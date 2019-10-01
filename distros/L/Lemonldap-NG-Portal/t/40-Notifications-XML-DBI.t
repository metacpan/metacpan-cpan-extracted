use Test::More;
use strict;
use IO::String;

my $res;
my $maintests = 8;

#my $maintests = 9;

require 't/test-lib.pm';
my $file = tempdb();

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
    $dbh->do(
qq{INSERT INTO notifications VALUES ('dwho','testref2','2016-05-30 00:00:00','<?xml version="1.0" encoding="UTF-8"?>
<root><notification uid="dwho" date="2016-05-30" reference="testref2">
<title>Test2 title</title>
<subtitle>Test2 subtitle</subtitle>
<text>This is a second test text</text>
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
          /<input type="hidden" name="reference[\dx]+" value="(\w+?)">/gs );
    ok( @refs == 2, 'Two notification references found' )
      or print STDERR Dumper( $res->[2]->[0] );

    ### TO BE FIXED
    # ok( $refs[0] eq 'testref2', '1st reference found is "testref2"' )
    #   or print STDERR Dumper( $res->[2]->[0] );
    # ok( $refs[1] eq 'testref', '2nd reference found is "testref"' )
    #   or print STDERR Dumper( $res->[2]->[0] );

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

    # Try to validate notifications
    $str =
'reference1x1=testref&check1x1x1=accepted&reference1x2=testref2&check1x2x1=accepted&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==';
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

    # Verify that notification was tagged as 'done'
    my $sth =
      $dbh->prepare('SELECT * FROM notifications WHERE done IS NOT NULL');
    $sth->execute;
    my $i = 0;
    while ( $sth->fetchrow_hashref ) { $i++ }
    ok( $i == 2, 'Notification was deleted' );

    clean_sessions();
}

count($maintests);
done_testing( count() );


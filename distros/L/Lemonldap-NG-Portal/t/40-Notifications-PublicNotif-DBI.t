use warnings;
use Test::More;
use strict;
use IO::String;
use JSON;

require 't/test-lib.pm';
my $maintests = 6;
my ( $res, $json );
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
q{INSERT INTO notifications VALUES ('public-error','testref','2016-05-30 00:00:00',?,null,null)}
    )->execute(
        '[
{
  "uid": "public-error",
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
q{INSERT INTO notifications VALUES ('public-error','testref2','2016-05-30 00:00:00',?,null,null)}
    )->execute(
        '[
{
  "date": "2016-05-30",
  "reference": "testref2",
  "title": "Test2 title",
  "subtitle": "Test2 subtitle",
  "text": "This is a test text"
}
]'
    );
        $dbh->prepare(
q{INSERT INTO notifications VALUES ('public-info','testref','2016-05-30 00:00:00',?,null,null)}
    )->execute(
        '
{
  "uid": "public-info",
  "title": "Test title",
  "subtitle": "Test subtitle",
  "text": "This is a test text"
}
'
    );

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => 'error',
                useSafeJail                => 1,
                notification               => 1,
                publicNotifications        => 1,
                oldNotifFormat             => 0,
                notificationStorage        => 'DBI',
                notificationStorageOptions => {
                    dbiChain => "dbi:SQLite:dbname=$file",
                },
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
    ok( $res->[2]->[0] =~ m%"public_errors":\[\{"%, 'Notification errors displayed' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%public-error%, 'Notification error displayed' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%testref2%, 'Notification error 2 displayed' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%public-info%, 'Notification info displayed' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%<script type="text/javascript" src="/static/common/js/carousel\.min\.js\?v=.+?"></script>%, 'Carousel min JS found' )
      or print STDERR Dumper( $res->[2]->[0] );
}

count($maintests);
done_testing( count() );

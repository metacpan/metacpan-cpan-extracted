# Test notifications explorer API

use strict;
use Data::Dumper;
use IO::String;
use JSON qw(from_json);
use Test::More;

my $count     = 0;
my $file      = 't/notifications.db';
my $maintests = 8;
my ( $res, $client );
eval { unlink $file };

sub count {
    my $c = shift;
    $count += $c if ($c);
    return $count;
}

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }

    my $dbh = DBI->connect("dbi:SQLite:dbname=$file");
    $dbh->do(
'CREATE TABLE notifications (uid text,ref text,date datetime,xml text,cond text,done datetime)'
    );

    use_ok('Lemonldap::NG::Manager::Cli::Lib');
    ok(
        $client = Lemonldap::NG::Manager::Cli::Lib->new(
            iniFile => 't/lemonldap-ng-dbi.ini'
        ),
        'Client object'
    );

    # Try to create a notification
    my $notif =
'{"date":"2099-05-03","uid":"dwho","reference":"Test","xml":"{\"title\":\"Test\"}"}';
    $res =
      $client->jsonPostResponse( 'notifications/actives', '',
        IO::String->new($notif),
        'application/json', length($notif) );

    ok( $res->{result}, 'Result is true' );

    # Test "actives" notification display
    displayTests('actives');

    # Mark notification as done
    $notif = '{"done":1}';
    $res   = $client->jsonPutResponse(
        'notifications/actives/dwho_Test',
        '', IO::String->new($notif),
        'application/json', length($notif)
    );
    ok( $res->{result} == 1, 'Result = 1' );

    # Test that notification is not active now
    $res =
      $client->jsonResponse( 'notifications/actives', 'groupBy=substr(uid,1)' );
    ok( $res->{result} == 1, 'Result = 1' );
    ok( $res->{count} == 0,  'Count = 0' );

    # Test "done" notifications display
    displayTests('done');

    # Delete notification
    $res =
      $client->_del('notifications/done/dwho_Test_20990503_dwho_VGVzdA==.done');
    $res =
      $client->jsonResponse( 'notifications/done', 'groupBy=substr(uid,1)' );
    ok( $res->{result} == 1, 'Result = 1' );
    ok( $res->{count} == 0, 'Count = 0' ) or diag Dumper($res);

    #print STDERR Dumper($res);
}

eval { unlink $file };
count($maintests);
done_testing( count() );

sub displayTests {
    my $type = shift;
    $res =
      $client->jsonResponse( "notifications/$type", 'groupBy=substr(uid,1)' );
    ok( $res->{result} == 1,                 'Result = 1' );
    ok( $res->{count} == 1,                  'Count = 1' );
    ok( $res->{values}->[0]->{value} eq 'd', 'Value is "d"' );
    count(3);

    $res = $client->jsonResponse( "notifications/$type", 'groupBy=uid' );
    ok( $res->{result} == 1,                    'Result = 1' );
    ok( $res->{count} == 1,                     'Count = 1' );
    ok( $res->{values}->[0]->{value} eq 'dwho', 'Value is "dwho"' );
    count(3);

    $res = $client->jsonResponse( "notifications/$type", 'uid=d*&groupBy=uid' );
    ok( $res->{result} == 1,                    'Result = 1' );
    ok( $res->{count} == 1,                     'Count = 1' );
    ok( $res->{values}->[0]->{value} eq 'dwho', 'Value is "dwho"' );
    count(3);

    $res = $client->jsonResponse( "notifications/$type", 'uid=d*' );
    ok( $res->{result} == 1,                  'Result = 1' );
    ok( $res->{count} == 1,                   'Count = 1' );
    ok( $res->{values}->[0]->{uid} eq 'dwho', 'Value is "dwho"' );
    count(3);

    $res = $client->jsonResponse( "notifications/$type", 'uid=dwho' );
    ok( $res->{result} == 1,                  'Result = 1' );
    ok( $res->{count} == 1,                   'Count = 1' );
    ok( $res->{values}->[0]->{uid} eq 'dwho', 'Value is "dwho"' );
    count(3);

    if ( $type eq 'actives' ) {
        $res = $client->jsonResponse( "notifications/$type/dwho_Test", '' );
        ok( $res->{result} == 1, 'Result = 1' );
        ok( $res->{count} == 1,  'Count = 1' );
        ok( eval { from_json( $res->{notifications}->[0] ) },
            'Response is JSON' )
          or print STDERR "Expect JSON, found:\n$res->{notifications}->[0]\n";
        count(3);
    }
}

# Remove notifications directory
`rm -rf t/notifications`;

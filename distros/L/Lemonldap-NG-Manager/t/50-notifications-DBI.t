# Test notifications explorer API

use strict;
use Data::Dumper;
use IO::String;
use JSON qw(from_json);
use Test::More;

my $count     = 0;
my $file      = 't/notifications.db';
my $maintests = 11;
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
'{"date":"2099-02-30","uid":"dwho","reference":"Test","xml":"{\"title\":\"Test\"}"}';
    $res =
      $client->jsonPostResponse( 'notifications/actives', '',
        IO::String->new($notif),
        'application/json', length($notif) );
    ok( $res->{error} =~ /^Notification not created: Bad date/,
        'Notification not inserted' );

    $notif =
'{"date":"2099-13-30","uid":"dwho","reference":"Test","xml":"{\"title\":\"Test\"}"}';
    $res =
      $client->jsonPostResponse( 'notifications/actives', '',
        IO::String->new($notif),
        'application/json', length($notif) );
    ok( $res->{error} =~ /^Notification not created: Bad date/,
        'Notification not inserted' );

    $notif =
'{"date":"2099-05_12","uid":"dwho","reference":"Test","xml":"{\"title\":\"Test\"}"}';
    $res =
      $client->jsonPostResponse( 'notifications/actives', '',
        IO::String->new($notif),
        'application/json', length($notif) );
    ok( $res->{error} =~ /^Malformed date$/, 'Notification not inserted' );

    $notif =
'{"date":"2099-12-31","uid":"dwho","reference":"Test","xml":"{\"title\":\"Test\"}"}';
    $res =
      $client->jsonPostResponse( 'notifications/actives', '',
        IO::String->new($notif),
        'application/json', length($notif) );
    $notif =
'{"date":"2099-12-31","uid":"dwho","reference":"Test2","xml":"{\"title\":\"Test\"}"}';
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
        '',                 IO::String->new($notif),
        'application/json', length($notif)
    );
    ok( $res->{result} == 1, 'Result = 1' );

    # Test that notification is not active now
    $res =
      $client->jsonResponse( 'notifications/actives', 'groupBy=substr(uid,1)' );
    ok( $res->{result} == 1, 'Result = 1' );
    ok( $res->{count} == 1,  'Count = 1' );

    # Test "done" notifications display
    displayTests('done');

    # Delete notification
    $res = $client->_del('notifications/done/dwho_Test_20991231');
    $res =
      $client->jsonResponse( 'notifications/done', 'groupBy=substr(uid,1)' );
    ok( $res->{result} == 1, 'Result = 1' );
    ok( $res->{count} == 0,  'Count = 0' ) or diag Dumper($res);
}

eval { unlink $file };
count($maintests);
done_testing( count() );

sub displayTests {
    my $type  = shift;
    my $count = $type eq 'actives' ? 2 : 1;

    $res =
      $client->jsonResponse( "notifications/$type", 'groupBy=substr(uid,1)' );
    ok( $res->{result} == 1,                 'Result = 1' );
    ok( $res->{count} == $count,             "Count = $count" );
    ok( $res->{values}->[0]->{value} eq 'd', 'Value is "d"' );
    count(3);

    $res = $client->jsonResponse( "notifications/$type", 'groupBy=uid' );
    ok( $res->{result} == 1,                    'Result = 1' );
    ok( $res->{count} == $count,                "Count = $count" );
    ok( $res->{values}->[0]->{value} eq 'dwho', 'Value is "dwho"' );
    count(3);

    $res = $client->jsonResponse( "notifications/$type", 'uid=d*&groupBy=uid' );
    ok( $res->{result} == 1,                    'Result = 1' );
    ok( $res->{count} == $count,                "Count = $count" );
    ok( $res->{values}->[0]->{value} eq 'dwho', 'Value is "dwho"' );
    count(3);

    $res = $client->jsonResponse( "notifications/$type", 'uid=d*' );
    ok( $res->{result} == 1,                  'Result = 1' );
    ok( $res->{count} == $count,              "Count = $count" );
    ok( $res->{values}->[0]->{uid} eq 'dwho', 'Value is "dwho"' );
    count(3);

    $res = $client->jsonResponse( "notifications/$type", 'uid=dwho' );
    ok( $res->{result} == 1,                  'Result = 1' );
    ok( $res->{count} == $count,              "Count = $count" );
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

    if ( $type eq 'done' ) {
        $res = $client->jsonResponse( "notifications/$type", 'uid=dwho' );
        ok(
            $res->{values}->[0]->{notification} =~
              /^\d{4}-\d{2}-\d{2}#dwho#Test$/,
            'Reference found'
        ) or diag Dumper($res);
        my $internal_ref = $res->{values}->[0]->{notification};
        my $ref          = $res->{values}->[0]->{reference};
        $internal_ref =~ s/#/_/g;    # Fix 2353
        $res = $client->jsonResponse("notifications/$type/$internal_ref")
          or diag Dumper($res);
        ok( $res = eval { from_json( $res->{notifications}->[0] ) },
            'Response is JSON' )
          or print STDERR "Expect JSON, found:\n$res->{notifications}->[0]\n";
        ok( $res->{reference} eq 'Test', 'reference found' )
          or diag Dumper($res);
        ok( $res->{title} eq 'Test', 'title found' )
          or diag Dumper($res);
        ok( $res->{date} eq '2099-12-31', 'date found' )
          or diag Dumper($res);
        ok( $res->{uid} eq 'dwho', 'uid found' )
          or diag Dumper($res);
        count(6);
    }
}

# Test notifications explorer API

use Test::More;
use strict;
use IO::String;
use JSON qw(from_json);

eval { mkdir 't/notifications' };
`rm -rf t/notifications/*`;
require 't/test-lib.pm';

# Try to create a notification
my $notif =
'{"date":"2099-02-30","uid":"dwho","reference":"Test","xml":"{\"title\":\"Test\"}"}';
my $res =
  &client->jsonPostResponse( 'notifications/actives', '',
    IO::String->new($notif),
    'application/json', length($notif) );
ok( $res->{error} =~ /^Notification not created: Bad date/,
    'Notification not inserted' );
count(1);

$notif =
'{"date":"2099-13-30","uid":"dwho","reference":"Test","xml":"{\"title\":\"Test\"}"}';
$res =
  &client->jsonPostResponse( 'notifications/actives', '',
    IO::String->new($notif),
    'application/json', length($notif) );
ok( $res->{error} =~ /^Notification not created: Bad date/,
    'Notification not inserted' );
count(1);

$notif =
'{"date":"2099-05_12","uid":"dwho","reference":"Test","xml":"{\"title\":\"Test\"}"}';
$res =
  &client->jsonPostResponse( 'notifications/actives', '',
    IO::String->new($notif),
    'application/json', length($notif) );
ok( $res->{error} =~ /^Malformed date$/, 'Notification not inserted' );
count(1);

$notif =
'{"date":"2099-12-31","uid":"dwho","reference":"Test","xml":"{\"title\":\"Test\"}"}';
$res =
  &client->jsonPostResponse( 'notifications/actives', '',
    IO::String->new($notif),
    'application/json', length($notif) );

ok( $res->{result}, 'Result is true' );
count(1);

# Test "actives" notification display
displayTests('actives');

# Mark notification as done
$notif = '{"done":1}';
$res   = &client->jsonPutResponse(
    'notifications/actives/dwho_Test',
    '',                 IO::String->new($notif),
    'application/json', length($notif)
);
ok( $res->{result} == 1, 'Result = 1' );

# Test that notification is not active now
$res =
  &client->jsonResponse( 'notifications/actives', 'groupBy=substr(uid,1)' );
ok( $res->{result} == 1, 'Result = 1' );
ok( $res->{count} == 0,  'Count = 0' );
count(3);

# Test "done" notifications display
displayTests('done');

# Delete notification
$res =
  &client->_del('notifications/done/dwho_Test_20991231_dwho_VGVzdA==.done');
$res = &client->jsonResponse( 'notifications/done', 'groupBy=substr(uid,1)' );
ok( $res->{result} == 1, 'Result = 1' );
ok( $res->{count} == 0,  'Count = 0' );
count(2);

#print STDERR Dumper($res);

`rm -f t/notifications/*`;

done_testing( count() );

sub displayTests {
    my $type = shift;
    $res =
      &client->jsonResponse( "notifications/$type", 'groupBy=substr(uid,1)' );
    ok( $res->{result} == 1,                 'Result = 1' );
    ok( $res->{count} == 1,                  'Count = 1' );
    ok( $res->{values}->[0]->{value} eq 'd', 'Value is "d"' );
    count(3);

    $res = &client->jsonResponse( "notifications/$type", 'groupBy=uid' );
    ok( $res->{result} == 1,                    'Result = 1' );
    ok( $res->{count} == 1,                     'Count = 1' );
    ok( $res->{values}->[0]->{value} eq 'dwho', 'Value is "dwho"' );
    count(3);

    $res = &client->jsonResponse( "notifications/$type", 'uid=d*&groupBy=uid' );
    ok( $res->{result} == 1,                    'Result = 1' );
    ok( $res->{count} == 1,                     'Count = 1' );
    ok( $res->{values}->[0]->{value} eq 'dwho', 'Value is "dwho"' );
    count(3);

    $res = &client->jsonResponse( "notifications/$type", 'uid=d*' );
    ok( $res->{result} == 1,                  'Result = 1' );
    ok( $res->{count} == 1,                   'Count = 1' );
    ok( $res->{values}->[0]->{uid} eq 'dwho', 'Value is "dwho"' );
    count(3);

    $res = &client->jsonResponse( "notifications/$type", 'uid=dwho' );
    ok( $res->{result} == 1,                  'Result = 1' );
    ok( $res->{count} == 1,                   'Count = 1' );
    ok( $res->{values}->[0]->{uid} eq 'dwho', 'Value is "dwho"' );
    count(3);

    if ( $type eq 'actives' ) {
        $res = &client->jsonResponse( "notifications/$type/dwho_Test", '' );
        ok( $res->{result} == 1, 'Result = 1' );
        ok( $res->{count} == 1,  'Count = 1' );
        ok( eval { from_json( $res->{notifications}->[0] ) },
            'Response is JSON' )
          or print STDERR "Expect JSON, found:\n$res->{notifications}->[0]\n";
        count(3);
    }

    if ( $type eq 'done' ) {
        $res = &client->jsonResponse( "notifications/$type", 'uid=dwho' );
        ok(
            $res->{values}->[0]->{notification} =~
              /^\d{8}_dwho_VGVzdA==\.done$/,
            'Reference found'
        ) or diag Dumper($res);
        my $internal_ref = $res->{values}->[0]->{notification};
        my $ref          = $res->{values}->[0]->{reference};
        $res = &client->jsonResponse("notifications/$type/$internal_ref");
        ok( $res->{done} eq $internal_ref, 'Internal reference found' )
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
        count(7);
    }
}

# Remove notifications directory
`rm -rf t/notifications`;

# Test notifications explorer API

use Test::More;
use strict;
use IO::String;

eval { mkdir 't/notifications' };
`rm -rf t/notifications/*`;
require 't/test-lib.pm';

# Try to create a notification
my $notif =
'{"date":"2015-05-03","uid":"dwho","reference":"Test","xml":"<title>Test</title>"}';
my $res =
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
    '', IO::String->new($notif),
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
  &client->_del('notifications/done/dwho_Test_20150503_dwho_VGVzdA==.done');
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
        ok( $res->{result} == 1,                     'Result = 1' );
        ok( $res->{count} == 1,                      'Count = 1' );
        ok( $res->{notifications}->[0] =~ /^<\?xml/, 'Response is XML' );
        count(3);
    }
}

# Remove notifications directory
`rm -rf t/notifications`;

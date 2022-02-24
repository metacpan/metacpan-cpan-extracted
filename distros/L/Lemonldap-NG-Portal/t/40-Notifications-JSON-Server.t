use Test::More;
use strict;
use IO::String;
use JSON qw(from_json);

BEGIN {
    require 't/test-lib.pm';
}

my $json = '{
"date": "2016-05-30 15:35:10",
"reference": "testref",
"uid": "dwho",
"title": "Test title",
"text": "This is a test text"
}';

my $bad_json = '{
"date": "2016-13-30 15:35:10",
"reference": "testref",
"uid": "dwho",
"title": "Test title",
"text": "This is a test text"
}';

my $bad_json2 = '{
"date": "2016-13_30 15:35:10",
"reference": "testref",
"uid": "dwho",
"title": "Test title",
"text": "This is a test text"
}';

my $jsonbis = '{
"date": "2016-05-31",
"reference": "testref",
"uid": "dwho",
"title": "Test2 title",
"text": "This is a second test text"
}';

my $json2 = q%{
"date": "2016-05-30",
"reference": "test_ref2",
"uid": "dwho",
"title": "Test2 title",
"text": "This is a second test text",
"subtitle": "Application 2",
"check": ["I agree","Yes, I'm sure"]
}%;

my $jsonall = '{
"date": "2016-05-30",
"reference": "testrefall",
"uid": "everyone",
"title": "Testall title",
"text": "This is a test text for all users"
}';

my $notifs = q%[{
 "uid": "dwho",
 "date": "2019-11-15 15:35:10",
 "reference": "ABC1",
 "title": "You have new authorizations",
 "subtitle": "Application 1",
 "text": "You have been granted to access to appli-1",
 "check": "I agree"
 },
 {
 "uid": "rtyler",
 "date": "2019-11-15",
 "reference": "ABC2",
 "title": "You have new authorizations",
 "subtitle": "Application 1",
 "text": "You have been granted to access to appli-1",
 "check": ["I agree", "I am sure"]
 },
 {
 "uid": "rtyler",
 "date": "2019-11-15",
 "reference": "ABC3",
 "condition": "$env->{REMOTE_ADDR} =~ /127.1.1.1/",
 "title": "You have new authorizations",
 "subtitle": "Application 1",
 "text": "You have been granted to access to appli-1",
 "check": ["I agree", "I am sure"]
 },
 {
 "uid": "rtyler",
 "date": "2050-11-15",
 "reference": "ABC4",
 "title": "You have new authorizations",
 "subtitle": "Application 1",
 "text": "You have been granted to access to appli-1",
 "check": ["I agree", "I am sure"]
 }
 ]%;

my $content = '{"uid":"dwho"}';

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel           => 'error',
            useSafeJail        => 1,
            notification       => 1,
            notificationServer => 1,         # POST method enabled if undefined
            notificationDefaultCond  => '$env->{REMOTE_ADDR} =~ /127.0.0.1/',
            notificationServerGET    => 1,
            notificationServerDELETE => 1,
            notificationServerSentAttributes =>
              'uid reference  date title text subtitle check',
            notificationWildcard       => 'everyone',
            notificationStorage        => 'File',
            notificationStorageOptions => {
                dirName => $main::tmpDir,
            },
        }
    }
);

my $res;
foreach ( $bad_json, $bad_json2 ) {
    ok(
        $res = $client->_post(
            '/notifications', IO::String->new($_),
            type   => 'application/json',
            length => length($_)
        ),
        "POST notification $_"
    );
    ok( $res->[2]->[0] =~ /"error"\s*:\s*"Bad date/,
        'Notification not inserted' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(2);
}

foreach ( $json, $json2, $jsonall ) {
    ok(
        $res = $client->_post(
            '/notifications', IO::String->new($_),
            type   => 'application/json',
            length => length($_)
        ),
        "POST notification $_"
    );
    ok( $res->[2]->[0] =~ /"result"\s*:\s*1/, 'Notification has been inserted' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(2);
}

ok(
    $res = $client->_get(
        '/notifications', type => 'application/json',
    ),
    'List notifications for "allusers"'
);
ok( $res->[2]->[0] =~ /"result"\s*:\s*/, 'Result found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok(
    $res->[2]->[0] =~ /"reference":"testrefall"/,
    'Notification for all users found'
) or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"uid":"everyone"/, 'Wildcard found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(4);

ok(
    $res = $client->_get(
        '/notifications/bad_uid', type => 'application/json',
    ),
    'List notifications for bad uid'
);
ok(
    $res->[2]->[0] =~ /"reference":"testrefall"/,
    'Notification for all users found'
) or print STDERR Dumper( $res->[2]->[0] );
count(2);

ok(
    $res = $client->_get(
        '/notifications/_allPending_', type => 'application/json',
    ),
    'List all pending notifications'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' );
ok( scalar @{ $json->{result} } == 3,             'Three notifications found' )
  or print STDERR Dumper($json);

foreach ( @{ $json->{result} } ) {
    ok( $_->{reference} =~ /^test-?ref/, "Reference \'$_->{reference}\' found" )
      or print STDERR Dumper($json);
    ok( $_->{uid} =~ /^(dwho|everyone)$/, "UID \'$_->{uid}\' found" )
      or print STDERR Dumper($json);
}
count(9);

ok(
    $res = $client->_get(
        '/notifications/dwho', type => 'application/json',
    ),
    'List notifications for "dwho"'
);
ok( $res->[2]->[0] =~ /"result"\s*:\s*/, 'Result found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"reference":"testref"/, 'First notification found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"reference":"test-ref2"/, 'Second notification found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok(
    $res->[2]->[0] =~ /"reference":"testrefall"/,
    'Third notification found (all users)'
) or print STDERR Dumper( $res->[2]->[0] );
count(5);

ok(
    $res = $client->_get(
        '/notifications/dwho/testref', type => 'application/json',
    ),
    'List notification with reference "testref"'
);
ok( $res->[2]->[0] =~ /"result"\s*:\s*/, 'Result found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"reference"\s*:\s*"testref"/,
    'Notification reference found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"title"\s*:\s*"Test title"/, 'Notification title found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"text"\s*:\s*"This is a test text"/,
    'Notification text found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"date"\s*:\s*"2016-05-30"/, 'Notification date found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"uid"\s*:\s*"dwho"/, 'Notification uid found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(7);

ok(
    $res = $client->_get(
        '/notifications/dwho/test-ref2',
        type => 'application/json',
    ),
    'List notification with reference "test-ref2"'
);
ok( $res->[2]->[0] =~ /"result"\s*:\s*/, 'Result found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"reference"\s*:\s*"test-ref2"/,
    'Notification reference found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"title"\s*:\s*"Test2 title"/,
    'Notification title found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"text"\s*:\s*"This is a second test text"/,
    'Notification text found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"date"\s*:\s*"2016-05-30"/, 'Notification date found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"uid"\s*:\s*"dwho"/, 'Notification uid found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"subtitle"\s*:\s*"Application 2"/,
    'Notification subtitle found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /"check":\["I agree","Yes, I\'m sure"\]/,
    'Notification check boxes found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(9);

ok(
    $res = $client->_put(
        '/notifications', IO::String->new($content),
        type   => 'application/json',
        length => length($content)
    ),
    'Try to delete notification with bad method'
);
ok( $res->[2]->[0] =~ /"error"\s*:\s*"Bad request"/, 'Bad method is refused' );
count(2);

foreach (qw(testrefall test-ref2)) {
    my $user = $_ eq 'testrefall' ? 'everyone' : 'dwho';
    ok(
        $res = $client->_delete(
            "/notifications/$user/$_", type => 'application/json',
        ),
        "Delete notification $_"
    );
    ok( $res->[2]->[0] =~ /"result"\s*:\s*1/, 'Notification has been deleted' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(2);
}

ok(
    $res = $client->_post(
        '/notifications', IO::String->new($jsonbis),
        type   => 'application/json',
        length => length($jsonbis)
    ),
    'Try to create the same notification twice'
);
ok(
    $res->[2]->[0] =~
      /"error"\s*:\s*"A notification already exists with reference testref"/,
    'Append the same notification is refused'
);
count(2);

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
my $id = expectCookie($res);
expectForm( $res, undef, '/notifback', 'reference1x1', 'url' );

# Insert combined notifications
ok(
    $res = $client->_post(
        '/notifications', IO::String->new($notifs),
        type   => 'application/json',
        length => length($notifs)
    ),
    "POST combined notifications $notifs"
);
ok( $res->[2]->[0] =~ /"result"\s*:\s*4/, 'Notifications have been inserted' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

ok(
    $res = $client->_get(
        '/notifications/_allExisting_',
        type => 'application/json',
    ),
    'List all existing notifications'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' );
ok( scalar @{ $json->{result} } == 5,             'Five notifications found' )
  or print STDERR Dumper($json);
count(3);

# Try to authenticate with "dwho"
# -------------------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'user=dwho&password=dwho'),
        accept => 'text/html',
        length => 23,
    ),
    'Auth query'
);
expectOK($res);
$id = expectCookie($res);
expectForm( $res, undef, '/notifback', 'reference1x1', 'reference1x2' );

ok(
    $res->[2]->[0] =~
      m%<input type="hidden" name="reference1x1" value="testref"/>%,
    'Checkbox is displayed'
) or print STDERR Dumper( $res->[2]->[0] );
ok(
    $res->[2]->[0] =~
      m%<input type="hidden" name="reference1x2" value="ABC1"/>%,
    'Checkbox is displayed'
) or print STDERR Dumper( $res->[2]->[0] );
ok(
    $res->[2]->[0] =~
m%<input class="form-check-input" type="checkbox" name="check1x2x1" id="1x2x1" value="accepted"/>%,
    'Checkbox is displayed'
) or print STDERR Dumper( $res->[2]->[0] );
my @c =
  ( $res->[2]->[0] =~ m%<input class="form-check-input" type="checkbox"%gs );

## One entry found
ok( @c == 1, ' -> One checkbox found' )
  or explain( $res->[2]->[0], "Number of checkbox(es) found = " . scalar @c );
count(6);

# Try to validate notification
my $str = 'reference1x2=ABC1&check1x2x1=accepted';
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
expectOK($res);
$id = expectCookie($res);
$client->logout($id);

# Try to authenticate with "rtyler"
# -------------------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'user=rtyler&password=rtyler'),
        accept => 'text/html',
        length => 27,
    ),
    'Auth query'
);
expectOK($res);
$id = expectCookie($res);
expectForm( $res, undef, '/notifback', 'reference1x1' );

ok(
    $res->[2]->[0] =~
m%<input class="form-check-input" type="checkbox" name="check1x1x1" id="1x1x1" value="accepted"/>%
      and m%<label class="form-check-label" for="1x1x1">I agree</label>%,
    'Checkbox is displayed'
) or print STDERR Dumper( $res->[2]->[0] );
ok(
    $res->[2]->[0] =~
m%<input class="form-check-input" type="checkbox" name="check1x1x2" id="1x1x2" value="accepted"/>%
      and m%<label class="form-check-label" for="1x1x2">I am sure</label>%,
    'Checkbox is displayed'
) or print STDERR Dumper( $res->[2]->[0] );
@c = ( $res->[2]->[0] =~ m%<input class="form-check-input" type="checkbox"%gs );

## Two entries found
ok( @c == 2, ' -> Two checkboxes found' )
  or explain( $res->[2]->[0], "Number of checkbox(es) found = " . scalar @c );
count(5);

# Try to validate notification
$str = 'reference1x1=ABC2&check1x1x1=accepted&check1x1x2=accepted';
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
expectOK($res);
$id = expectCookie($res);
$client->logout($id);

ok(
    $res = $client->_get(
        '/notifications/_allPending_', type => 'application/json',
    ),
    'List all pending notifications'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' );
ok( scalar @{ $json->{result} } == 3,             'Three notifications found' )
  or print STDERR Dumper($json);
count(3);

clean_sessions();
done_testing( count() );

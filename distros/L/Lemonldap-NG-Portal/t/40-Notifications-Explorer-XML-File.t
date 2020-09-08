use Test::More;
use strict;
use IO::String;
use JSON qw(from_json);

require 't/test-lib.pm';

my $res;
my $file      = "$main::tmpDir/20160530_dwho_dGVzdHJlZg==.xml";
my $maintests = 39;

SKIP: {
    eval { require XML::LibXML; require XML::LibXSLT; };
    if ($@) {
        skip 'XML::LibX* not found', $maintests;
    }

    open F, "> $file" or die($!);
    print F '<?xml version="1.0" encoding="UTF-8"?>
<root><notification uid="dwho" date="2016-05-30" reference="testref">
<title>Test title</title>
<subtitle>Test subtitle</subtitle>
<text>This is a test text</text>
<check>Accept test</check>
<check>Accept test2</check>
</notification><notification uid="dwho" date="2016-05-30" reference="testref2">
<title>Test title</title>
<subtitle>Test subtitle</subtitle>
<text>This is a test text</text>
<check>Accept test</check>
<check>Accept test2</check>
</notification></root>';
    close F;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => 'error',
                useSafeJail                => 1,
                notification               => 1,
                notificationStorage        => 'File',
                notificationStorageOptions => { dirName => $main::tmpDir },
                portalMainLogo             => 'common/logos/logo_llng_old.png',
                oldNotifFormat             => 1,
                checkUser                  => 1,
                notificationsExplorer      => 1
            }
        }
    );

    # Try to authenticate
    # -------------------
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
    count(1);
    expectOK($res);
    my $id = expectCookie($res);
    expectForm( $res, undef, '/notifback', 'reference1x1' );

    # Verify that cookie is ciphered (session invalid)
    ok(
        $res = $client->_get(
            '/', cookie => "lemonldap=$id",
        ),
        'Test cookie received'
    );
    expectReject($res);

    # Try to authenticate
    # -------------------
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
    count(1);
    expectOK($res);
    $id = expectCookie($res);
    expectForm( $res, undef, '/notifback', 'reference1x1', 'reference1x2' );

    # Verify that cookie is ciphered (session invalid)
    ok(
        $res = $client->_get(
            '/', cookie => "lemonldap=$id",
        ),
        'Test cookie received'
    );
    count(1);
    expectReject($res);

    # Try to validate notification with accepting all checkboxes
    my $str =
'reference1x1=testref&check1x1x1=accepted&check1x1x2=accepted&reference1x2=testref2&check1x2x1=accepted&check1x2x2=accepted';
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
    $file =~ s/xml$/done/;
    ok( -e $file, 'Notification was deleted' );

    $id = expectCookie($res);

    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'New auth query'
    );
    expectAuthenticatedAs( $res, 'dwho' );
    ok( $res->[2]->[0] =~ /yourApp/s, 'Menu displayed' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res->[2]->[0] =~
          m%<span trspan="notificationsExplorer">notificationsExplorer</span>%,
        'Link found'
    ) or print STDERR Dumper( $res->[2]->[0] );

    # GET notifications explorer
    ok(
        $res = $client->_get(
            '/mynotifications',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Notifications explorer query'
    );
    ok( $res->[2]->[0] =~ m%<span id="languages"></span>%,
        ' Language icons found' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res->[2]->[0] =~ m%<span id="msg" trspan=\'myNotifications\'></span>%,
        ' trspan="myNotifications" found'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%<th><span trspan="date">Date</span></th>%,
        ' trspan="date" found' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res->[2]->[0] =~ m%<th><span trspan="reference">Reference</span></th>%,
        ' trspan="reference" found'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%<th><span trspan="action">Action</span></th>%,
        ' trspan="action" found' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%<td class="data-epoch">\d{10}</td>%,
        ' epoch found' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%<td class="align-middle">testref</td>%,
        ' testref found' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%<td class="align-middle">testref2</td>%,
        ' testref2 found' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%class="fa fa-eye"></span>%, ' fa-eye found' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res->[2]->[0] =~
          m%<span id=\'icon-testref2-\d{10}\' class="fa fa-eye"></span>%,
        ' fa-eye 2 found'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%<span id=\'displayNotif\'></span>%,
        ' Notififcation container found' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%class="verify" trspan="verify">Verify</span>%,
        ' trspan="verify" found' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ /notifications\.(?:min\.)?js/,
        'Found NOTIFICATIONS js' )
      or print STDERR Dumper( $res->[2]->[0] );

    # GET notification testref
    $res->[2]->[0] =~
m%<span notif=\'testref\' epoch=\'(\d{10})\' class="btn btn-success" role="button">%;
    ok(
        $res = $client->_get(
            '/mynotifications/testref',
            query  => "epoch=$1",
            cookie => "lemonldap=$id",
        ),
        'Display testref notification query'
    );
    my $json;
    ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    ok( $json->{result} == 1, ' Result is 1' )
      or explain( $json, "result => 1" );
    ok(
        $json->{notification} =~
          m%<input type="hidden" name="reference1x1" value="testref">%,
        ' Hidden input found'
    ) or explain( $json, "Hidden input" );
    ok( $json->{notification} =~ m%<h2 class="notifText">Test title</h2>%,
        ' <h2> tag found' )
      or explain( $json, "<h2> tag" );
    ok( $json->{notification} =~ m%<h3 class="notifText">Test subtitle</h3>%,
        ' <h3> tag found' )
      or explain( $json, "<h3> tag" );
    ok(
        $json->{notification} =~
          m%<p class="notifText">This is a test text</p>%,
        ' <p> tag found'
    ) or explain( $json, "<p> tag" );
    ok( $json->{notification} =~ m%checked disabled name="check1x1x1"%,
        ' Checkbox 1 found' )
      or explain( $json, "Checkbox 1" );
    ok( $json->{notification} =~ m%checked disabled name="check1x1x2"%,
        ' Checkbox 2 found' )
      or explain( $json, "Chekbox 2" );

    # Malformed request
    ok(
        $res = $client->_get(
            '/mynotifications/testref', cookie => "lemonldap=$id",
        ),
        'Malformed query'
    );
    ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    ok( $json->{error} eq 'Missing epoch parameter',
        ' Missing epoch parameter' )
      or explain( $json, "Missing epoch parameter" );

    # Bad request
    ok(
        $res = $client->_get(
            '/mynotifications/testref',
            query  => "epoch=1234567890",
            cookie => "lemonldap=$id",
        ),
        'Bad query'
    );
    ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    ok( !$json->{result}, ' Result is 0' )
      or explain( $json, "result => 0" );
    ok( !$json->{notification}, ' Notification is 0' )
      or explain( $json, "notification => 0" );

    # CheckUser form
    # ------------------------
    ok(
        $res = $client->_get(
            '/checkuser',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'CheckUser form',
    );
    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/checkuser', 'user', 'url' );
    ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%,
        'Found trspan="checkUser"' )
      or explain( $res->[2]->[0], 'trspan="checkUser"' );
    ok( $res->[2]->[0] !~ m%<td scope="row">notification_%,
        'Notification "testref" not found' )
      or explain( $res->[2]->[0], 'notification_testref' );

    clean_sessions();
    unlink $file;
}

count($maintests);
done_testing( count() );

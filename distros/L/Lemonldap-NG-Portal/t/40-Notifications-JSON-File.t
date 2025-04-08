use warnings;
use Test::More;
use strict;
use IO::String;
use JSON;

require 't/test-lib.pm';
use Lemonldap::NG::Portal::Main::Constants 'PE_NOTIFICATION';

my $res;
my $json;

mkdir("$main::tmpDir/notifications");

sub getfilename {
    my ( $date, $uid, $reference ) = @_;
    my $url      = encodeUrl($reference);
    my $pathdate = $date =~ s/-//gr;

    return "$main::tmpDir/notifications/${pathdate}_${uid}_${url}.json";
}

sub check_deleted {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $date, $uid, $reference, $expected ) = @_;
    my $file = getfilename( $date, $uid, $reference );

    $file =~ s/json$/done/;

    if ($expected) {
        ok( -e $file, 'Notification was deleted' );
    }
    else {
        ok( !-e $file, 'Notification was not deleted' );
    }
    count(1);
}

sub store_notification {
    my ( $date, $uid, $reference ) = @_;

    my $file = getfilename( $date, $uid, $reference );

    open F, "> $file" or die($!);
    print F to_json( [ {
                "uid"       => $uid,
                "date"      => $date,
                "reference" => $reference,
                "title"     => "Test title",
                "subtitle"  => "Test subtitle",
                "text"      => 'This is a test text for $uid',
                "check"     => [ "Accept test", "Accept test2" ]
            }
        ]
    );
    close F;
}

sub clean_notifications {
    unlink( glob("$main::tmpDir/notifications/*") );
}

sub test {
    my ( $client, $reference ) = @_;

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new(
'user=dwho&password=dwho&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw=='
            ),
            length => 64,
        ),
        'Auth query (JSON required)'
    );
    ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    ok( $json->{result} == 0, ' Good result' )
      or explain( $json, 'result => 0' );
    ok( $json->{error} == PE_NOTIFICATION, ' Notificationtion is pending' )
      or explain( $json, 'error => 36' );
    my $id = $json->{ciphered_id};

    # Verify that cookie can be deciphered (ciphered_id is valid)
    ok(
        $res = $client->_get(
            '/notifback',
            accept => 'text/html',
            cookie => "lemonldap=$id"
        ),
        'Test received Id'
    );
    count(5);
    expectForm( $res, undef, '/notifback', 'reference1x1', 'url' );

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
    count(1);
    expectOK($res);
    $id = expectCookie($res);
    expectForm( $res, undef, '/notifback', 'reference1x1', 'url' );

    # Verify that cookie is ciphered (session invalid)
    ok(
        $res = $client->_get(
            '/',
            query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==',
            cookie => "lemonldap=$id",
        ),
        'Test received cookie'
    );
    count(1);
    expectReject($res);

    # Try to cancel notification
    ok(
        $res = $client->_get(
            '/notifback',
            query  => "cancel=1",
            cookie => "lemonldap=$id",
            length => 64,
            accept => 'text/html',
        ),
        "Cancel notification"
    );

    my $c = getCookies($res);
    ok( not( $c->{'lemonldap'} ), 'Cookie expired' ) or print STDERR Dumper($c);
    count(2);
    expectRedirection( $res, 'http://auth.example.com/' );

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
    count(1);
    expectOK($res);
    $id = expectCookie($res);
    expectForm( $res, undef, '/notifback', 'reference1x1', 'url' );

    is(
        getHtmlElement( $res, '//p[@class="notifText"]/text()' )->pop()->data,
        "This is a test text for dwho",
        "Found notification text"
    );
    count(1);

    # Verify that cookie is ciphered (session invalid)
    ok(
        $res = $client->_get(
            '/',
            query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==',
            cookie => "lemonldap=$id",
        ),
        'Test cookie received'
    );
    count(1);
    expectReject($res);

    # Try to validate notification without accepting it
    ok(
        $res = $client->_post(
            '/notifback',
            {
                reference1x1 => $reference,
                url          => encodeUrl("http://test1.example.com/"),
            },
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        "Don't accept notification"
    );
    ok( $res->[2]->[0] =~ qr%<h2 class="notifText">Test title</h2>%,
        'Notification displayed' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(2);

    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );
    count(1);

    # Try to validate notification without accepting it
    ok(
        $res = $client->_post(
            '/notifback',
            {
                reference1x1 => $reference,
                url          => encodeUrl("http://test1.example.com/"),
            },
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        "Don't accept notification"
    );
    ok( $res->[2]->[0] =~ qr%<h2 class="notifText">Test title</h2>%,
        'Notification displayed' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(2);

    # Try to validate notification without accepting it
    ok(
        $res = $client->_post(
            '/notifback',
            {
                reference1x1 => $reference,
                url          => encodeUrl("http://test1.example.com/"),
            },
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        "Don't accept notification"
    );
    ok( $res->[2]->[0] =~ qr%<h2 class="notifText">Test title</h2>%,
        'Notification displayed' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(2);

    # Try to validate notification with accepting just one checkbox
    ok(
        $res = $client->_post(
            '/notifback',
            {
                reference1x1 => $reference,
                check1x1x1   => "accepted",
                url          => encodeUrl("http://test1.example.com/"),
            },
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        "Don't accept notification - Accept just one checkbox"
    );
    ok( $res->[2]->[0] =~ qr%<h2 class="notifText">Test title</h2>%,
        'Notification displayed' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(2);

    # Try to validate notification with accepting all checkboxes
    ok(
        $res = $client->_post(
            '/notifback',
            {
                reference1x1 => $reference,
                check1x1x1   => "accepted",
                check1x1x2   => "accepted",
                url          => encodeUrl("http://test1.example.com/"),
            },
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        "Accept notification"
    );
    expectRedirection( $res, qr/./ );

    count(1);
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
    ok( $res->[2]->[0] =~ /yourApp/s, 'Menu displayed' );
    count(2);
}

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                   => 'error',
            useSafeJail                => 1,
            notification               => 1,
            notificationStorage        => 'File',
            notificationStorageOptions =>
              { dirName => "$main::tmpDir/notifications" },
            oldNotifFormat => 0,
            portalMainLogo => 'common/logos/logo_llng_old.png',
        }
    }
);

# Accept personal notification
clean_notifications;
store_notification( "2016-05-30", "dwho", "testref" );
test( $client, "testref" );
check_deleted( "2016-05-30", "dwho", "testref", 1 );

# Accept global notification
store_notification( "2016-06-30", "allusers", "testrefall" );
test( $client, "testrefall" );
check_deleted( "2016-06-30", "dwho", "testref", 0 );

# Accept another personal notification
store_notification( "2016-07-30", "dwho", "testref2" );
test( $client, "testref2" );
check_deleted( "2016-07-30", "dwho", "testref2", 1 );

# Accept another global notification
store_notification( "2016-08-30", "allusers", "testrefall2" );
test( $client, "testrefall2" );
check_deleted( "2016-08-30", "allusers", "testrefall2", 0 );

done_testing( count() );

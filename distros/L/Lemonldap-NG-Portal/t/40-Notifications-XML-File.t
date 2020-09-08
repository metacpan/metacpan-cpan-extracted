use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $file      = "$main::tmpDir/20160530_dwho_dGVzdHJlZg==.xml";
my $maintests = 15;

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
</notification></root>';
    close F;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => 'error',
                useSafeJail                => 1,
                notification               => 1,
                notificationStorage        => 'File',
                notificationStorageOptions => { dirName => $main::tmpDir },
                oldNotifFormat             => 1,
                portalMainLogo             => 'common/logos/logo_llng_old.png',
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
    count(1);
    expectOK($res);
    my $id = expectCookie($res);
    expectForm( $res, undef, '/notifback', 'reference1x1', 'url' );

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
    ok( $res->[2]->[0] =~ qr%<h2 class="notifText">Test title</h2>%,
        'Notification displayed' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );

    # Try to validate notification without accepting it
    $str = 'reference1x1=testref&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==';
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
    ok( $res->[2]->[0] =~ qr%<h2 class="notifText">Test title</h2>%,
        'Notification displayed' )
      or print STDERR Dumper( $res->[2]->[0] );

    # Try to validate notification without accepting it
    $str = 'reference1x1=testref&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==';
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
    ok( $res->[2]->[0] =~ qr%<h2 class="notifText">Test title</h2>%,
        'Notification displayed' )
      or print STDERR Dumper( $res->[2]->[0] );

    # Try to validate notification with accepting just one checkbox
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
        "Don't accept notification - Accept just one checkbox"
    );
    ok( $res->[2]->[0] =~ qr%<h2 class="notifText">Test title</h2>%,
        'Notification displayed' )
      or print STDERR Dumper( $res->[2]->[0] );

    # Try to validate notification with accepting all ckeckboxes
    $str =
'reference1x1=testref&check1x1x1=accepted&check1x1x2=accepted&url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==';
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
    expectRedirection( $res, qr/./ );
    $file =~ s/xml$/done/;
    ok( -e $file, 'Notification was deleted' );

    $id = expectCookie($res);

    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            length => 64,
            accept => 'text/html',
        ),
        'New auth query'
    );
    expectAuthenticatedAs( $res, 'dwho' );
    ok( $res->[2]->[0] =~ /yourApp/s, 'Menu displayed' );

    #print STDERR Dumper($res);

    clean_sessions();

    unlink $file;

}

count($maintests);
done_testing( count() );

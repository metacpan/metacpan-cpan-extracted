use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;

BEGIN {
    require 't/test-lib.pm';
}

my $maintests = 13;
my $client;

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.example.com(.*)#, ' @ SOAP REQUEST @' );
        my $url = $1;
        my $res;
        my $s = $req->content;
        ok(
            $res = $client->_post(
                $url,
                IO::String->new($s),
                length => length($s),
                type   => $req->header('Content-Type'),
                custom => {
                    HTTP_SOAPACTION => $req->header('Soapaction'),
                },
            ),
            ' Execute request'
        );
        expectOK($res);
        ok( getHeader( $res, 'Content-Type' ) =~ m#^(?:text|application)/xml#,
            ' Content is XML' )
          or explain( $res->[1], 'Content-Type => application/xml' );
        pass(' @ END OF SOAP REQUEST @');
        count(4);
        return $res;
    }
);

my $xml = '<?xml version="1.0" encoding="UTF-8"?>
<root><notification uid="dwho" date="2016-05-30 15:35:10" reference="testref">
<title>Test title</title>
<subtitle>Test subtitle</subtitle>
<text>This is a test text</text>
</notification></root>';

my $xmlbis = '<?xml version="1.0" encoding="UTF-8"?>
<root><notification uid="dwho" date="2016-05-31" reference="testref">
<title>Test title</title>
<subtitle>Test subtitle</subtitle>
<text>This is a test text</text>
</notification></root>';

my $combined = '<?xml version="1.0" encoding="UTF-8"?>
<root><notification uid="dwho" date="2016-05-31 15:35:10" reference="ABC1">
<title>Test title</title>
<subtitle>Test subtitle</subtitle>
<text>This is a test text</text>
<check>I agree</check>
</notification>
<notification uid="rtyler" date="2016-05-31" reference="AB_C_2">
<title>Test title</title>
<subtitle>Test subtitle</subtitle>
<text>This is a test text</text>
<check>I agree</check>
<check>I am sure</check>
</notification>
<notification uid="rtyler" date="2016-05-31" reference="ABC3" condition="\$env->{REMOTE_ADDR} =~ /127\.1\.1\.1/">
<title>Test title</title>
<subtitle>Test subtitle</subtitle>
<text>This is a test text</text>
<check>I agree</check>
<check>I am sure</check>
</notification>
<notification uid="rtyler" date="2050-05-31" reference="ABC4">
<title>Test title</title>
<subtitle>Test subtitle</subtitle>
<text>This is a test text</text>
<check>I agree</check>
<check>I am sure</check>
</notification>
</root>';

SKIP: {
    eval "use SOAP::Lite; use  XML::LibXML; use XML::LibXSLT;";
    if ($@) {
        skip 'SOAP::Lite or XML::Lib* not found', $maintests;
    }

    $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel           => 'error',
                useSafeJail        => 1,
                notification       => 1,
                notificationServer => 1,

            #notificationDefaultCond    => '$env->{REMOTE_ADDR} =~ /127.0.0.1/',
                notificationStorage        => 'File',
                notificationStorageOptions => {
                    dirName => $main::tmpDir
                },
                oldNotifFormat => 1,
            }
        }
    );
    my $soap;
    ok(
        $soap =
          SOAP::Lite->new( proxy => 'http://auth.example.com/notifications' ),
        'SOAP client'
    );
    $soap->default_ns('urn:Lemonldap/NG/Common/PSGI/SOAPService');
    ok(
        $soap->call( 'newNotification', $xml )->result() == 1,
        ' Append a notification -> SOAP call returns 1'
    );
    $soap->default_ns('urn:Lemonldap/NG/Common/PSGI/SOAPService');
    ok(
        $soap->call( 'newNotification', $xmlbis )->result() == 0,
        ' Append the same notification twice -> SOAP call returns 0'
    );

    # Try to authenticate
    # -------------------
    my $res;
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
    my $id = expectCookie($res);
    expectForm( $res, undef, '/notifback', 'reference1x1', 'url' );

    # Insert combined notifications
    $soap->default_ns('urn:Lemonldap/NG/Common/PSGI/SOAPService');
    ok(
        $soap->call( 'newNotification', $combined )->result() == 4,
        ' Append a notification -> SOAP call returns 4'
    );

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
    expectForm( $res, undef, '/notifback', 'reference1x1', 'reference2x1' );
    my @c = ( $res->[2]->[0] =~ m%<input type="checkbox"%gs );

    ## One entry found
    ok( @c == 1, ' -> One checkbox found' )
      or
      explain( $res->[2]->[0], "Number of checkbox(es) found = " . scalar @c );

    # Try to validate notification
    my $str = 'reference1x1=ABC1&check1x1x1=accepted';
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
          m%<input type="hidden" name="reference1x1" value="AB-C-2">%,
        'Reference found'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res->[2]->[0] =~
m%<input type="checkbox" name="check1x1x1" id="check1x1x1" value="accepted">I agree</label>%,
        'Checkbox is displayed'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res->[2]->[0] =~
m%<input type="checkbox" name="check1x1x2" id="check1x1x2" value="accepted">I am sure</label>%,
        'Checkbox is displayed'
    ) or print STDERR Dumper( $res->[2]->[0] );
    @c = ( $res->[2]->[0] =~ m%<input type="checkbox"%gs );

    ## Two entries found
    ok( @c == 2, ' -> Two checkboxes found' )
      or
      explain( $res->[2]->[0], "Number of checkbox(es) found = " . scalar @c );

}

count($maintests);
clean_sessions();
done_testing( count() );

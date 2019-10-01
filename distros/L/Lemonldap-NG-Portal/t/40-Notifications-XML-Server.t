use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;

BEGIN {
    require 't/test-lib.pm';
}

my $maintests = 4;
my $debug     = 'error';
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
<root><notification uid="dwho" date="2016-05-30" reference="testref">
<title>Test title</title>
<subtitle>Test subtitle</subtitle>
<text>This is a test text</text>
</notification></root>';

my $xml2 = '<?xml version="1.0" encoding="UTF-8"?>
<root><notification uid="dwho" date="2016-05-31" reference="testref">
<title>Test title</title>
<subtitle>Test subtitle</subtitle>
<text>This is a test text</text>
</notification></root>';

SKIP: {
    eval "use SOAP::Lite; use  XML::LibXML; use XML::LibXSLT;";
    if ($@) {
        skip 'SOAP::Lite or XML::Lib* not found', $maintests;
    }

    $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => 'error',
                useSafeJail                => 1,
                notification               => 1,
                notificationServer         => 1,
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
        $soap->call( 'newNotification', $xml2 )->result() == 0,
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

}

count($maintests);
clean_sessions();
done_testing( count() );

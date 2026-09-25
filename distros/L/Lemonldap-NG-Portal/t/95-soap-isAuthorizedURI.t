use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;

BEGIN {
    require 't/test-lib.pm';
}

my $maintests = 16;
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

SKIP: {
    eval 'use SOAP::Lite';
    if ($@) {
        skip 'SOAP::Lite not found', $maintests;
    }

    $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel          => 'error',
                authentication    => 'Demo',
                userDB            => 'Same',
                soapSessionServer => 1,
                locationRules     => {
                    'auth.example.com'  => { default => 'accept' },
                    'test1.example.com' => {
                        '^/deny' => 'deny',
                        default  => 'accept',
                    },
                },
            }
        }
    );

    my $id = $client->login('dwho');

    my $soap;
    ok(
        $soap = SOAP::Lite->new( proxy => 'http://auth.example.com/sessions' ),
        'SOAP client'
    );

    # The URL is percent-decoded and normalized by the web server before the
    # request is routed to the application: rules must be tested against the
    # same canonical value, else they can be bypassed with an encoded URL.
    foreach my $url (
        'http://test1.example.com/deny',        # no encoding
        'http://test1.example.com/%64eny',      # "d" encoded
        'http://test1.example.com/den%79',      # "y" encoded
        'http://test1.example.com/./deny',      # dot segment
        'http://test1.example.com/foo/../deny', # dot segment
        'http://test1.example.com//deny',       # duplicate slash
        'http://test1.example.com/%2Fdeny',     # encoded slash
      )
    {
        $soap->default_ns('urn:Lemonldap/NG/Common/PSGI/SOAPService');
        my $call;
        ok( $call = $soap->call( 'isAuthorizedURI', $id, $url ),
            "SOAP call for $url" );
        my $res = $call->result();
        ok( !$res, "Authorization refused for $url" );
    }

    # Negative control: this URL is decoded as /denY, the rule ^/deny must not
    # apply, so authorization must be granted.
    $soap->default_ns('urn:Lemonldap/NG/Common/PSGI/SOAPService');
    my $res = $soap->call( 'isAuthorizedURI', $id,
        'http://test1.example.com/den%59' )->result();
    ok( $res, 'Authorization granted for http://test1.example.com/den%59' );
}

count($maintests);
clean_sessions();
done_testing( count() );

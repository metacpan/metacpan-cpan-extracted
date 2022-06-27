#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use vars qw( $DEBUG );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'HTTP::Promise::Parser' );
    use HTTP::Promise::Headers;
};

use strict;
use warnings;

subtest "headers" => sub
{
    # Borrowed from Session Initiation Protocol Torture Test Messages
    my $message = join( "\x0D\x0A", split( /\n/, <<'EOM', -1 ), '' );
TO :
 sip:john.doe@somewhere.example.com ;   tag    = 1234567890n
from   : "Bob \\\""       <sip:bob@example.com>
  ;
  tag = 12abcd3
MaX-fOrWaRdS: 0010
Call-ID: john.doe@192.0.1.2
Content-Length   : 150
cseq: 0009
  INVITE
Via  : SIP  /   2.0
 /UDP
    192.0.1.3;branch=123abcdef
s :
NewFangledHeader:   newfangled value
 continued newfangled value
UnknownHeaderWithUnusualValue: ;;,,;;,;
Content-Type: application/sdp
Route:
 <sip:services.example.com;lr;unknownwith=value;unknown-no-value>
v:  SIP  / 2.0  / TCP     maybe.example.com   ;
  branch  =   a1bC2dE3fgh4  ,
 SIP  /    2.0   / UDP  192.168.255.123   ; branch=
 a1bC2dE3fgh4
m:"Quoted string \"\"" <sip:bob@example.com> ; newparam =
      newvalue ;
  secondparam ; q = 0.33

EOM

    my $expected = { headers => HTTP::Promise::Headers->new(
        'to'                            => 'sip:john.doe@somewhere.example.com ; tag = 1234567890n',
        'from'                          => '"Bob \\\\\"" <sip:bob@example.com> ; tag = 12abcd3',
        'max-forwards'                  => '0010',
        'call-id'                       => 'john.doe@192.0.1.2',
        'content-length'                => '150',
        'cseq'                          => '0009 INVITE',
        'via'                           => 'SIP / 2.0 /UDP 192.0.1.3;branch=123abcdef',
        's'                             => '',
        'newfangledheader'              => 'newfangled value continued newfangled value',
        'unknownheaderwithunusualvalue' => ';;,,;;,;',
        'content-type'                  => 'application/sdp',
        'route'                         => '<sip:services.example.com;lr;unknownwith=value;unknown-no-value>',
        'v'                             => 'SIP / 2.0 / TCP maybe.example.com ; branch = a1bC2dE3fgh4 , SIP / 2.0 / UDP 192.168.255.123 ; branch= a1bC2dE3fgh4',
        'm'                             => '"Quoted string \"\"" <sip:bob@example.com> ; newparam = newvalue ; secondparam ; q = 0.33',
    ), length => 764 };

    my $p = HTTP::Promise::Parser->new( debug => $DEBUG );
    my $headers = $p->parse_headers( \$message );
    is_deeply( $headers, $expected, "Parsed headers" );
};

subtest "request" => sub
{
    my @good = 
    (
        "GET / HTTP/1.1\x0D\x0A\x0D\x0A",
        { method => 'GET', uri => '/', protocol => 'HTTP/1.1', version => 1.1, headers => [], content => \'', length => 16 },
        'Request #1',

        "GET /a/b/c/d HTTP/1.1\x0D\x0A\x0D\x0A",
        { method => 'GET', uri => '/a/b/c/d', protocol => 'HTTP/1.1', version => 1.1, headers => [], content => \'', length => 23 },
        'Request #1.1',

        "GET / HTTP/1.1\x0D\x0A"
      . "Content-Length: 1000\x0D\x0A"
      . "\x0D\x0A",
        { method => 'GET', uri => '/', protocol => 'HTTP/1.1', version => 1.1, headers => [ 'content-length' => '1000' ], content => \'', length => 38 },
        'Request #4 with header',

        "GET / HTTP/1.1\x0D\x0A"
      . "Content-Length\x0D\x0A :\x0D\x0A 1000\x0D\x0A"
      . "\x0D\x0A",
        { method => 'GET', uri => '/', protocol => 'HTTP/1.1', version => 1.1, headers => [ 'content-length' => '1000' ], content => \'', length => 43 },
        'Request #5 with LWS before and after colon',

        "GET / HTTP/1.1\x0D\x0A"
      . "Content-Length\x0D\x0A : \x0D\x0A  1\x0D\x0A    0\x0D\x0A    0\x0D\x0A    0  \x0D\x0A"
      . "\x0D\x0A",
        { method => 'GET', uri => '/', protocol => 'HTTP/1.1', version => 1.1, headers => [ 'content-length' => '1 0 0 0' ], content => \'', length => 65 },
        'Request #6 with leading and trailing LWS and between field-content',

        "POST / HTTP/1.1\x0D\x0A\x0D\x0AMyBody",
        { method => 'POST', uri => '/', protocol => 'HTTP/1.1', version => 1.1, headers => [], content => \'MyBody', length => 17 },
        'Request #7 with body',

        "POST / HTTP/1.1\x0D\x0A"
      . "Content-Length: 6\x0D\x0A"
      . "\x0D\x0A"
      . "MyBody",
        { method => 'POST', uri => '/', protocol => 'HTTP/1.1', version => 1.1, headers => [ 'content-length' => '6' ], content => \'MyBody', length => 36 },
        'Request #8 with headers and body',

        "GET / HTTP/1.1\x0A\x0A",
        { method => 'GET', uri => '/', protocol => 'HTTP/1.1', version => 1.1, headers => [], content => \'', length => 15 },
        'Request #10 only LF in request line RFC 2616 19.3',
    
        "GET /\x0D\x0A\x0D\x0A",
        { method => 'GET', uri => '/', protocol => 'HTTP/0.9', version => 0.9, headers => [], content => \'', length => 7 },
        'Request #11 RFC 1945 5.0 (Simple-Request)',
    );

    while( my( $message, $expected, $test ) = splice( @good, 0, 3 ) )
    {
        diag( "Parsing request:\n${message}" ) if( $DEBUG );
        my $p = HTTP::Promise::Parser->new( debug => $DEBUG );
        my $request = $p->parse_request_pp( \$message );
        diag( "Error parsing request '$test': ", $p->error ) if( $DEBUG && !defined( $request ) );
        $expected->{headers} = HTTP::Promise::Headers->new( @{$expected->{headers}} );
        is_deeply( $request, $expected, "Parsed $test" );
    }

    my @bad = 
    (
        "\x0D\x0AGET / HTTP/1.1\x0D\x0A\x0D\x0A",
        qr/^Bad request/i,
        'Request #2 with leading empty line',

        "\x0D\x0A\x0D\x0AGET / HTTP/1.1\x0D\x0A\x0D\x0A",
        qr/^Bad request/i,
        'Request #3 with leading empty lines',

        "GET / HTTP/12.12\x0D\x0A\x0D\x0A",
        qr/^Bad request/i,
        'Request #9 with future HTTP version',
    
        "GET / HTTP/1.1\x0D\x0A",
        qr/^Incomplete request/i,
        'Request #12 missing end of the header fields CRLF',

        "G<E>T / HTTP/1.1\x0D\x0A\x0D\x0A",
        qr/^Bad request/i,
        'Request #13 Method contains seperator chars',

        "GET / XXXX/1.1\x0D\x0A\x0D\x0A",
        qr/^Bad request-line/i,
        'Request #14 Invalid HTTP version',

        "POST / HTTP/1.1\x0D\x0A"
      . "Content-Length: 6"
      . "\x0D\x0A"
      . "MyBody",
        qr/^Incomplete request/i,
        'Request #15 missing CRLF after header',

        "POST / HTTP/1.1\x0D\x0A"
      . "Content<->Length: 6\x0D\x0A"
      . "\x0D\x0A"
      . "MyBody",
        qr/^Bad request/i,
        'Request #16 invalid chars in field-name',

        "GET /sss/ /ss HTTP/1.1\x0D\x0A\x0D\x0A",
        qr/^Bad request-line/i,
        'Request #17 Invalid LWS in uri',
    
        "GET /sss/\x0D\x0AHost: example.org\x0D\x0A\x0D\x0A",
        qr/^Bad request/i,
        'Request #18 Simple-Request does not allow headers',
    );

    while( my( $message, $expected, $test ) = splice( @bad, 0, 3 ) )
    {
        diag( "Parsing request:\n${message}" ) if( $DEBUG );
        my $rv = HTTP::Promise::Parser->parse_request_pp( \$message );
        ok( !$rv, "Returned value for $test" );
        my $ex = HTTP::Promise::Parser->error;
        isa_ok( $ex => 'HTTP::Promise::Exception' );
        if( $ex )
        {
            like( $ex->message, $expected, "Bad request: $test" );
        }
        else
        {
            fail( "Failed $test" );
        }
    }
};

subtest "response" => sub
{
    my @good = (
        "HTTP/1.1 200 OK\x0D\x0A\x0D\x0A",
        { protocol => 'HTTP/1.1', version => 1.1, code => 200, status => 'OK', headers => [], content => \'', length => 17 },
        'Response #1',

        "HTTP/1.1 200 OK\x0D\x0A"
      . "Content-Length: 1000\x0D\x0A"
      . "\x0D\x0A",
        { protocol => 'HTTP/1.1', version => 1.1, code => 200, status => 'OK', headers => [ 'content-length' => '1000' ], content => \'', length => 39 },
        'Response #2 with header',

        "HTTP/1.1 200 OK\x0D\x0A"
      . "Content-Length\x0D\x0A :\x0D\x0A 1000\x0D\x0A"
      . "\x0D\x0A",
        { protocol => 'HTTP/1.1', version => 1.1, code => 200, status => 'OK', headers => [ 'content-length' => '1000' ], content => \'', length => 44 },
        'Response #3 with LWS before and after colon',

        "HTTP/1.1 200 OK\x0D\x0A"
      . "Content-Length\x0D\x0A : \x0D\x0A  1\x0D\x0A    0\x0D\x0A    0\x0D\x0A    0  \x0D\x0A"
      . "\x0D\x0A",
        { protocol => 'HTTP/1.1', version => 1.1, code => 200, status => 'OK', headers => [ 'content-length' => '1 0 0 0' ], content => \'', length => 66 },
        'Response #4 with leading and trailing LWS and between field-content',

        "HTTP/1.1 200 OK\x0D\x0A\x0D\x0AMyBody",
        { protocol => 'HTTP/1.1', version => 1.1, code => 200, status => 'OK', headers => [], content => \'MyBody', length => 17 },
        'Response #5 with body',

        "HTTP/1.1 200 OK\x0D\x0A"
      . "Content-Length: 6\x0D\x0A"
      . "\x0D\x0A"
      . "MyBody",
        { protocol => 'HTTP/1.1', version => 1.1, code => 200, status => 'OK', headers => [ 'content-length' => '6' ], content => \'MyBody', length => 36 },
        'Response #6 with headers and body',

        "HTTP/1.1 200 \x0D\x0A\x0D\x0A",
        { protocol => 'HTTP/1.1', version => 1.1, code => 200, status => '', headers => [], content => \'', length => 15 },
        'Response #8 without a Reason-Phrase',
    
        "HTTP/1.1 200 OK\x0A\x0A",
        { protocol => 'HTTP/1.1', version => 1.1, code => 200, status => 'OK', headers => [], content => \'', length => 16 },
        'Response #9 only LF in request line RFC 2616 19.3',
    );

    while( my( $message, $expected, $test ) = splice( @good, 0, 3 ) )
    {
        my $response = HTTP::Promise::Parser->parse_response_pp( \$message );
        $expected->{headers} = HTTP::Promise::Headers->new( @{$expected->{headers}} );
        is_deeply( $response, $expected, "Parsed $test" );
    }

    my @bad = (
        "HTTP/12.12 200 OK\x0D\x0A\x0D\x0A",
        qr/^Bad Response/i,
        'Response #7 with future HTTP version',
    
        "HTTP/1.1 200 OK\x0D\x0A",
        qr/^Incomplete request/i,
        'Response #10 missing end of the header fields CRLF',

        "XXXX/1.1 200 OK\x0D\x0A\x0D\x0A",
        qr/^Bad response/i,
        'Response #11 Invalid HTTP version',

        "HTTP/1.1 200 OK\x0D\x0A"
      . "Content-Length: 6"
      . "\x0D\x0A"
      . "MyBody",
        qr/^Incomplete request/i,
        'Response #12 missing CRLF after header',

        "HTTP/1.1 200 OK\x0D\x0A"
      . "Content<->Length: 6\x0D\x0A"
      . "\x0D\x0A"
      . "MyBody",
        qr/^Bad response/i,
        'Response #13 invalid chars in field-name',
    );

    while( my( $message, $expected, $test ) = splice( @bad, 0, 3 ) )
    {
        my $rv = HTTP::Promise::Parser->parse_response_pp( \$message );
        ok( !$rv, "Returned value for $test" );
        my $ex = HTTP::Promise::Parser->error;
        isa_ok( $ex => 'HTTP::Promise::Exception' );
        if( $ex )
        {
            like( $ex->message, $expected, "Bad request: $test" );
        }
        else
        {
            fail( "Failed $test" );
        }
    }
};

done_testing();

__END__



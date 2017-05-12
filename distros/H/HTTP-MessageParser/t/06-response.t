#!perl

use strict;
use warnings;

use Test::More;

plan tests => 14;

use_ok( 'HTTP::MessageParser' );

my @good = (
    "HTTP/1.1 200 OK\x0D\x0A\x0D\x0A",
    [ 'HTTP/1.1', '200', 'OK', [], \'' ],
    'Response A',

    "HTTP/1.1 200 OK\x0D\x0A"
  . "Content-Length: 1000\x0D\x0A"
  . "\x0D\x0A",
    [ 'HTTP/1.1', '200', 'OK', [ 'content-length' => '1000' ], \'' ],
    'Response B with header',

    "HTTP/1.1 200 OK\x0D\x0A"
  . "Content-Length\x0D\x0A :\x0D\x0A 1000\x0D\x0A"
  . "\x0D\x0A",
    [ 'HTTP/1.1', '200', 'OK', [ 'content-length' => '1000' ], \'' ],
    'Response C with LWS before and after colon',

    "HTTP/1.1 200 OK\x0D\x0A"
  . "Content-Length\x0D\x0A : \x0D\x0A  1\x0D\x0A    0\x0D\x0A    0\x0D\x0A    0  \x0D\x0A"
  . "\x0D\x0A",
    [ 'HTTP/1.1', '200', 'OK', [ 'content-length' => '1 0 0 0' ], \'' ],
    'Response D with leading and trailing LWS and between field-content',

    "HTTP/1.1 200 OK\x0D\x0A\x0D\x0AMyBody",
    [ 'HTTP/1.1', '200', 'OK', [], \'MyBody' ],
    'Response E with body',

    "HTTP/1.1 200 OK\x0D\x0A"
  . "Content-Length: 6\x0D\x0A"
  . "\x0D\x0A"
  . "MyBody",
    [ 'HTTP/1.1', '200', 'OK', [ 'content-length' => '6' ], \'MyBody' ],
    'Response F with headers and body',

    "HTTP/12.12 200 OK\x0D\x0A\x0D\x0A",
    [ 'HTTP/12.12', '200', 'OK', [], \'' ],
    'Response G with future HTTP version',
    
    "HTTP/1.1 200 \x0D\x0A\x0D\x0A",
    [ 'HTTP/1.1', '200', '', [], \'' ],
    'Response H without a Reason-Phrase',
    
    "HTTP/1.1 200 OK\x0A\x0A",
    [ 'HTTP/1.1', '200', 'OK', [], \'' ],
    'Response I only LF in request line RFC 2616 19.3',
);

while ( my ( $message, $expected, $test ) = splice( @good, 0, 3 ) ) {
    my $response = [ HTTP::MessageParser->parse_response(\$message) ];
    is_deeply $response, $expected, "Parsed $test";
}


my @bad = (
    "HTTP/1.1 200 OK\x0D\x0A",
    qr/^Bad Response/,
    'Response J missing end of the header fields CRLF',

    "XXXX/1.1 200 OK\x0D\x0A\x0D\x0A",
    qr/^Bad Status-Line/,
    'Response K Invalid HTTP version',

    "HTTP/1.1 200 OK\x0D\x0A"
  . "Content-Length: 6"
  . "\x0D\x0A"
  . "MyBody",
    qr/^Bad Response/,
    'Response L missing CRLF after header',

    "HTTP/1.1 200 OK\x0D\x0A"
  . "Content<->Length: 6\x0D\x0A"
  . "\x0D\x0A"
  . "MyBody",
    qr/^Bad Response/,
    'Request M invalid chars in field-name',
);

while ( my ( $message, $expected, $test ) = splice( @bad, 0, 3 ) ) {
    eval { HTTP::MessageParser->parse_response(\$message) };
    like $@, $expected, "Failed $test";
}

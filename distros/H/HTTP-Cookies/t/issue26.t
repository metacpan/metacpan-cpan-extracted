use strict;
use Test::More;
use HTTP::Cookies;
use HTTP::Response;
use HTTP::Request;

my $CRLF="\015\012";

my $cookie_jar = HTTP::Cookies->new();

my $request = HTTP::Request->new(GET => 'http://www.en.com/');

my $response = HTTP::Response->parse
        ("HTTP/1.1 302 Moved" . $CRLF . "Set-Cookie: expires=10101$CRLF$CRLF");

$response->request($request);

$cookie_jar->extract_cookies($response);

is $cookie_jar->as_string(), 'Set-Cookie3: expires=10101; path="/"; domain=www.en.com; discard; version=0' . "\n";

done_testing;

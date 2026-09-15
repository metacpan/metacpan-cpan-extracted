use v5.36;
use strict;
use warnings;

use Test::More;
use Linux::Event::HTTP::_HTTP1;

my $parser = 'Linux::Event::HTTP::_HTTP1';

sub parse_request ($wire) {
    return $parser->parse_request($wire);
}

sub parse_error ($wire) {
    my $ok = eval {
        $parser->parse_request($wire);
        1;
    };
    return ($ok, $@);
}

my $none = parse_request(
    "GET / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "\r\n"
);

is($none->body_mode, 'none', 'request without framing headers has no body');
ok(!defined $none->content_length, 'no Content-Length returns undef');
ok($none->keep_alive, 'HTTP/1.1 is persistent by default');

my $fixed = parse_request(
    "POST /upload HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Content-Length: 5\r\n" .
    "\r\n" .
    "hello"
);

is($fixed->body_mode, 'content-length', 'Content-Length selects fixed body mode');
is($fixed->content_length, 5, 'Content-Length is retained as a number');
ok($fixed->keep_alive, 'fixed-length request remains persistent');

my $zero = parse_request(
    "POST /empty HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Content-Length: 0\r\n" .
    "\r\n"
);
is($zero->body_mode, 'content-length', 'Content-Length zero still records framing mode');
is($zero->content_length, 0, 'Content-Length zero is preserved');

my $duplicate_same = parse_request(
    "POST / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Content-Length: 7\r\n" .
    "Content-Length: 7\r\n" .
    "\r\n"
);
is($duplicate_same->content_length, 7, 'identical duplicate Content-Length is accepted');

my $combined_same = parse_request(
    "POST / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Content-Length: 7, 7\r\n" .
    "\r\n"
);
is($combined_same->content_length, 7, 'identical comma-combined Content-Length is accepted');

my ($ok, $error) = parse_error(
    "POST / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Content-Length: 7\r\n" .
    "Content-Length: 8\r\n" .
    "\r\n"
);
ok(!$ok, 'conflicting duplicate Content-Length is rejected');
like($error, qr/400.*Content-Length/, 'conflicting Content-Length is a 400 semantic error');

($ok, $error) = parse_error(
    "POST / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Content-Length: 7, 8\r\n" .
    "\r\n"
);
ok(!$ok, 'conflicting combined Content-Length is rejected');
like($error, qr/400.*Content-Length/, 'combined Content-Length conflict is a 400 semantic error');

($ok, $error) = parse_error(
    "POST / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Content-Length: 184467440737095516160\r\n" .
    "\r\n"
);
ok(!$ok, 'overflowing Content-Length is rejected');
like($error, qr/400.*Content-Length/, 'overflowing Content-Length is a 400 semantic error');

my $chunked = parse_request(
    "POST / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Transfer-Encoding: chunked\r\n" .
    "\r\n"
);
is($chunked->body_mode, 'chunked', 'chunked Transfer-Encoding selects chunked body mode');
ok(!defined $chunked->content_length, 'chunked request has no Content-Length');

($ok, $error) = parse_error(
    "POST / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Transfer-Encoding: chunked\r\n" .
    "Content-Length: 5\r\n" .
    "\r\n"
);
ok(!$ok, 'Transfer-Encoding plus Content-Length is rejected');
like($error, qr/400.*Transfer-Encoding.*Content-Length/, 'TE plus CL is a 400 framing error');

($ok, $error) = parse_error(
    "POST / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Transfer-Encoding: chunked, gzip\r\n" .
    "\r\n"
);
ok(!$ok, 'non-final chunked coding is rejected');
like($error, qr/400.*chunked/, 'non-final chunked coding is a 400 framing error');

($ok, $error) = parse_error(
    "POST / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Transfer-Encoding: chunked, chunked\r\n" .
    "\r\n"
);
ok(!$ok, 'chunked applied twice is rejected');
like($error, qr/400.*chunked/, 'repeated chunked coding is a 400 framing error');

($ok, $error) = parse_error(
    "POST / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Transfer-Encoding: gzip, chunked\r\n" .
    "\r\n"
);
ok(!$ok, 'unsupported transfer coding is rejected');
like($error, qr/501.*unsupported transfer coding/, 'unsupported transfer coding is classified as 501');

($ok, $error) = parse_error(
    "POST / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Transfer-Encoding: chunked;foo=bar\r\n" .
    "\r\n"
);
ok(!$ok, 'parameters on chunked are rejected');
like($error, qr/400.*Transfer-Encoding/, 'invalid chunked parameters are a 400 semantic error');

($ok, $error) = parse_error(
    "GET / HTTP/1.1\r\n" .
    "\r\n"
);
ok(!$ok, 'HTTP/1.1 request without Host is rejected');
like($error, qr/400.*Host/, 'missing Host is a 400 semantic error');

($ok, $error) = parse_error(
    "GET / HTTP/1.1\r\n" .
    "Host: one.test\r\n" .
    "Host: two.test\r\n" .
    "\r\n"
);
ok(!$ok, 'multiple Host fields are rejected');
like($error, qr/400.*Host/, 'multiple Host fields are a 400 semantic error');

($ok, $error) = parse_error(
    "GET / HTTP/1.1\r\n" .
    "Host: bad host\r\n" .
    "\r\n"
);
ok(!$ok, 'Host containing whitespace is rejected');
like($error, qr/400.*Host/, 'invalid Host is a 400 semantic error');

my $ipv6 = parse_request(
    "GET / HTTP/1.1\r\n" .
    "Host: [::1]:8080\r\n" .
    "\r\n"
);
is($ipv6->header('Host'), '[::1]:8080', 'bracketed IPv6 Host is accepted');

my $close = parse_request(
    "GET / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Connection: close\r\n" .
    "\r\n"
);
ok(!$close->keep_alive, 'Connection close disables HTTP/1.1 persistence');

my $close_wins = parse_request(
    "GET / HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Connection: keep-alive, close\r\n" .
    "\r\n"
);
ok(!$close_wins->keep_alive, 'Connection close wins over keep-alive');

my $http10 = parse_request(
    "GET / HTTP/1.0\r\n" .
    "\r\n"
);
ok(!$http10->keep_alive, 'HTTP/1.0 closes by default');
is($http10->body_mode, 'none', 'HTTP/1.0 request without framing has no body');

my $http10_keep = parse_request(
    "GET / HTTP/1.0\r\n" .
    "Connection: keep-alive\r\n" .
    "\r\n"
);
ok($http10_keep->keep_alive, 'HTTP/1.0 keep-alive option enables persistence');

done_testing;

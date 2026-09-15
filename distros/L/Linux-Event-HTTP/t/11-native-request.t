use v5.36;
use strict;
use warnings;

use Test::More;
use Linux::Event::HTTP::_HTTP1;

my $parser = 'Linux::Event::HTTP::_HTTP1';

my $head = join '',
    "GET /hello?x=1 HTTP/1.1\r\n",
    "Host: example.test\r\n",
    "X-Test: one\r\n",
    "X-Test: two\r\n",
    "X_Legal: underscore\r\n",
    "\r\n";

my $buffer = $head . 'BODY';
my $request = $parser->parse_request($buffer);

isa_ok($request, 'Linux::Event::HTTP::Request');
is($request->_consumed, length($head), 'native request retains consumed header length');
is($request->method, 'GET', 'method materializes on access');
is($request->target, '/hello?x=1', 'target materializes on access');
is($request->version, '1.1', 'shared Request version accessor reads native protocol state');
is($request->header_count, 4, 'native request retains header count');

is($request->header('host'), 'example.test', 'header lookup is ASCII case-insensitive');
is($request->header('HOST'), 'example.test', 'header lookup accepts uppercase query');
is($request->header('X-Test'), 'one', 'header returns first duplicate value');
is_deeply(
    $request->header_values('x-test'),
    [ 'one', 'two' ],
    'header_values returns duplicate values in wire order',
);

is($request->header('X_Legal'), 'underscore', 'legal underscore header remains addressable');
ok(!defined $request->header('X-Legal'), 'underscore and hyphen header names remain distinct');

is($request->header_name(0), 'Host', 'original header name is preserved');
is($request->header_value(0), 'example.test', 'indexed header value is available lazily');
is($request->header_name(3), 'X_Legal', 'indexed access preserves legal header spelling');
ok(!defined($request->header_name(4)), 'past-end header name index returns undef');
ok(!defined($request->header_value(4)), 'past-end header value index returns undef');

my $error = eval { $request->header_name(-1); 1 };
ok(!$error, 'negative header name index is rejected');
like($@, qr/non-negative integer/, 'negative header index error is clear');

$error = eval { $request->header_value('x'); 1 };
ok(!$error, 'non-integer header value index is rejected');
like($@, qr/non-negative integer/, 'non-integer header index error is clear');

$error = eval { $request->method('POST'); 1 };
ok(!$error, 'parsed request method is read-only');
like($@, qr/read-only/, 'parsed request mutation error is clear');

$error = eval { $request->header('X-Test', 'changed'); 1 };
ok(!$error, 'parsed request headers are read-only');
like($@, qr/read-only/, 'parsed request header mutation error is clear');

ok(!defined $request->body, 'parsed Request does not implicitly buffer incoming body bytes');
ok(!$request->has_buffered_body, 'parsed Request reports no buffered body');
ok(!$request->is_mutable, 'parsed Request reports immutable state');
ok($request->headers_are_lossless, 'parsed Request reports lossless headers');
ok($request->target_is_exact, 'parsed Request reports exact request-target');

substr($buffer, 0, 3, 'PUT');
$buffer =~ s/example\.test/changed.invalid/;
is($request->method, 'GET', 'request state is independent of later source-buffer mutation');
is($request->header('Host'), 'example.test', 'native request owns stable header bytes');

my $partial = substr($head, 0, 20);
ok(!defined $parser->parse_request($partial), 'native parser returns undef for incomplete request');

my $malformed = eval {
    $parser->parse_request("GET / HTTP/1.1\r\nBad Header: value\r\n\r\n");
    1;
};
ok(!$malformed, 'native parser rejects malformed request');
like($@, qr/malformed HTTP\/1 request/, 'native malformed-request error is clear');

my $second = "GET /second HTTP/1.1\r\nHost: example.test\r\n\r\n";
my $pipeline = $head . $second;
my $first = $parser->parse_request($pipeline);
is($first->_consumed, length($head), 'native request consumes only first pipelined head');
is($first->target, '/hello?x=1', 'native request represents first pipelined request');

undef $request;
pass('native request destruction completed');

done_testing;

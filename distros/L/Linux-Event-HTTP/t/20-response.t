use v5.36;
use strict;
use warnings;

use Test::More;
use Linux::Event::HTTP::Response;
use Linux::Event::HTTP::_HTTP1 ();

my $class = 'Linux::Event::HTTP::Response';
ok($class->can('new'), 'Response exposes a public message constructor');

my $response = $class->new(status => 200);

my $server_request = Linux::Event::HTTP::_HTTP1->parse_request(
    "GET / HTTP/1.1\r\nHost: example.test\r\n\r\n",
);
my $server_default = $class->_new_server_default($server_request);
is($server_default->status, 200,
    'trusted server Response exposes implicit default status');
is($server_default->version, '1.1',
    'trusted server Response exposes implicit HTTP/1.1 version');
is($server_default->header_count, 0,
    'trusted server Response exposes implicit empty headers');
is(
    $server_default->_serialize_head('1.1'),
    "HTTP/1.1 200 OK\r\n\r\n",
    'trusted server Response serializes implicit defaults',
);
$server_default->add_header('X-Test', 'yes');
is($server_default->status, 200,
    'metadata mutation preserves implicit default status');
is($server_default->version, '1.1',
    'metadata mutation preserves implicit server version');
is($server_default->header('X-Test'), 'yes',
    'trusted server Response materializes header storage on mutation');

my $server_request_10 = Linux::Event::HTTP::_HTTP1->parse_request(
    "GET / HTTP/1.0\r\n\r\n",
);
my $server_default_10 = $class->_new_server_default($server_request_10);
is($server_default_10->version, '1.0',
    'compact server Response preserves HTTP/1.0 version');

is($response->status, 200, 'status getter returns initial status');
ok(!defined $response->reason, 'reason is optional');
is($response->version, '1.1', 'response defaults to HTTP version 1.1');
ok(!$response->is_complete, 'response without a selected body is not yet complete');
ok(!$response->has_buffered_body, 'response without body has no buffered body');
ok($response->is_mutable, 'response is mutable before commit');
ok($response->headers_are_lossless, 'response reports lossless headers');
$response->version('1.0');
is($response->version, '1.0', 'response version is mutable before commit');
$response->version('1.1');

my $first_empty = $class->new(version => '1.0');
is($first_empty->status, 200, 'new response uses the default status');
is($first_empty->version, '1.0', 'constructor accepts HTTP version');
is($first_empty->header('X-Missing'), undef, 'new response starts without headers');
is(
    $first_empty->_serialize_head('1.0'),
    "HTTP/1.0 200 OK\r\n\r\n",
    'new response with shared empty headers serializes normally',
);
$first_empty->add_header('X-First', 'yes');
is($first_empty->header('X-First'), 'yes', 'response lazily owns added headers');

my $second_empty = $class->new(version => '1.0');
is(
    $second_empty->header('X-First'),
    undef,
    'adding a header does not mutate another Response',
);

$response->header('Content-Type', 'text/plain');
is($response->header('content-type'), 'text/plain', 'header lookup is case-insensitive');

$response->add_header('Set-Cookie', 'a=1');
$response->add_header('Set-Cookie', 'b=2');
is_deeply(
    $response->header_values('set-cookie'),
    [ 'a=1', 'b=2' ],
    'repeated response headers preserve order',
);
is($response->header_count, 3, 'response exposes exact header count');
is($response->header_name(1), 'Set-Cookie', 'response preserves indexed header name');
is($response->header_value(2), 'b=2', 'response preserves indexed header value');
ok(!defined($response->header_name(3)), 'past-end response header name returns undef');
ok(!defined($response->header_value(3)), 'past-end response header value returns undef');

is(
    $response->_serialize_head('1.1'),
    "HTTP/1.1 200 OK\r\n" .
    "Content-Type: text/plain\r\n" .
    "Set-Cookie: a=1\r\n" .
    "Set-Cookie: b=2\r\n" .
    "\r\n",
    'native serializer produces a valid HTTP/1.1 response head',
);

$response->status(404)->reason('Gone Here');
is(
    $response->_serialize_head('1.0'),
    "HTTP/1.0 404 Gone Here\r\n" .
    "Content-Type: text/plain\r\n" .
    "Set-Cookie: a=1\r\n" .
    "Set-Cookie: b=2\r\n" .
    "\r\n",
    'serializer supports HTTP/1.0 and custom reason phrase',
);

$response->reason(undef);
like(
    $response->_serialize_head('1.1'),
    qr/\AHTTP\/1\.1 404 Not Found\r\n/,
    'HTTP/1 serializer may choose a standard wire reason without changing message reason',
);
ok(!defined $response->reason, 'message reason remains undef after serialization');

$response->header('Content-Type', 'application/json');
is_deeply(
    $response->header_values('Content-Type'),
    [ 'application/json' ],
    'header setter replaces fields of same name',
);
is($response->header_name(0), 'Content-Type',
    'header replacement retains first matching field position');

my $duplicate_replace = $class->new(
    headers => [
        [ 'X-Dupe', 'first' ],
        [ 'X-Keep', 'middle' ],
        [ 'x-dupe', 'second' ],
        [ 'X-Last', 'last' ],
    ],
);
$duplicate_replace->header('X-Dupe', 'final');
is_deeply(
    $duplicate_replace->header_values('x-dupe'),
    [ 'final' ],
    'header setter collapses duplicate same-name fields',
);
is_deeply(
    [
        map {
            [
                $duplicate_replace->header_name($_),
                $duplicate_replace->header_value($_),
            ]
        } 0 .. $duplicate_replace->header_count - 1
    ],
    [
        [ 'X-Dupe', 'final' ],
        [ 'X-Keep', 'middle' ],
        [ 'X-Last', 'last' ],
    ],
    'duplicate replacement preserves the first field position and unrelated order',
);

$response->remove_header('Set-Cookie');
is_deeply(
    $response->header_values('Set-Cookie'),
    [],
    'remove_header removes all same-name fields',
);

my $with_length = $class->new(
    status => 200,
    headers => [
        [ 'Content-Length', '0' ],
    ],
);
is($with_length->content_length, 0, 'response exposes declared Content-Length');
like(
    $with_length->_serialize_head('1.1'),
    qr/Content-Length: 0\r\n\r\n\z/,
    'decimal Content-Length serializes',
);

my $no_content_length = $class->new(
    status => 204,
    headers => [
        [ 'Content-Length', '0' ],
    ],
);
my $no_content_ok = eval { $no_content_length->_serialize_head('1.1'); 1 };
ok(!$no_content_ok, '204 response cannot emit Content-Length');
like($@, qr/204.*Content-Length/, '204 Content-Length rejection is clear');

my $body_response = $class->new(body => "hello\n");
is($body_response->body, "hello\n", 'constructor accepts a complete scalar body');
ok($body_response->has_buffered_body,
    'complete scalar body is reported as buffered');
ok($body_response->is_complete,
    'complete scalar body makes the Response message complete immediately');
$body_response->header('X-After-Body', 'yes');
is($body_response->header('X-After-Body'), 'yes',
    'message completion does not commit mutable response metadata');

my $ok = eval { $class->new(status => 99); 1 };
ok(!$ok, 'invalid status is rejected');
like($@, qr/status/, 'invalid status error is clear');

$ok = eval { $class->new(status => 600); 1 };
ok(!$ok, 'status above Uniform contract range is rejected');
like($@, qr/100 and 599/, 'high status rejection is clear');

$ok = eval { $response->header('Bad Header', 'value'); 1 };
ok(!$ok, 'invalid response field name is rejected');
like($@, qr/field name/, 'invalid field name error is clear');

$ok = eval { $response->header('X-Test', "safe\r\nInjected: yes"); 1 };
ok(!$ok, 'CRLF response splitting attempt is rejected');
like($@, qr/control characters/, 'CRLF rejection error is clear');

$ok = eval { $response->reason("Bad\nReason"); 1 };
ok(!$ok, 'newline in reason phrase is rejected');
like($@, qr/reason phrase/, 'invalid reason phrase error is clear');

$ok = eval { $response->_serialize_head('2'); 1 };
ok(!$ok, 'HTTP/2 cannot use HTTP/1 serializer');
like($@, qr/version/, 'invalid serializer version error is clear');

my $both = $class->new(
    headers => [
        [ 'Content-Length', '3' ],
        [ 'Transfer-Encoding', 'chunked' ],
    ],
);
$ok = eval { $both->_serialize_head('1.1'); 1 };
ok(!$ok, 'response TE plus CL is rejected');
like($@, qr/both Transfer-Encoding and Content-Length/, 'response TE plus CL error is clear');

my $duplicate_length = $class->new(
    headers => [
        [ 'Content-Length', '3' ],
        [ 'Content-Length', '3' ],
    ],
);
$ok = eval { $duplicate_length->_serialize_head('1.1'); 1 };
ok(!$ok, 'multiple response Content-Length fields are rejected');
like($@, qr/multiple Content-Length/, 'duplicate response Content-Length error is clear');

my $bad_length = $class->new(
    headers => [
        [ 'Content-Length', '3, 3' ],
    ],
);
$ok = eval { $bad_length->_serialize_head('1.1'); 1 };
ok(!$ok, 'serializer only emits canonical decimal Content-Length');
like($@, qr/decimal number/, 'non-canonical response Content-Length error is clear');

# Serializer validates again in case internals are modified directly.
my $tampered = $class->new;
$tampered->{headers} = [ [ 'Bad Header', 'x' ] ];
$ok = eval { $tampered->_serialize_head('1.1'); 1 };
ok(!$ok, 'native serializer revalidates tampered field names');

$tampered->{headers} = [ [ 'X-Test', "x\0y" ] ];
$ok = eval { $tampered->_serialize_head('1.1'); 1 };
ok(!$ok, 'native serializer revalidates tampered field values');

ok(!$class->can('stream_body'),
    'Response message does not expose a transport body producer');
ok(!$class->can('connection'),
    'Response message does not retain a transport Connection');
ok(!$class->can('request'),
    'Response message does not retain a peer Request');
ok(!$class->can('upgrade'),
    'Response message does not perform protocol Upgrade');

my $committed = $class->new;
$committed->_commit;
ok(!$committed->is_mutable, 'committed Response reports immutable state');
$ok = eval { $committed->status(201); 1 };
ok(!$ok, 'response metadata locks after message commit');
like($@, qr/cannot change/, 'metadata lock error is clear');

done_testing;

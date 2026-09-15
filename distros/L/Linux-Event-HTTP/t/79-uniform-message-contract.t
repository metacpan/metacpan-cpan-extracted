use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::Response;
use Linux::Event::HTTP::_HTTP1;

my @common = qw(
    version header header_values header_count header_name header_value
    add_header remove_header body has_buffered_body is_complete is_mutable
    headers_are_lossless
);

my $request = Linux::Event::HTTP::Request->new(
    method => 'POST',
    target => '/items?draft=1',
    headers => [
        [ 'X-First', 'before' ],
        [ 'X-Trace', 'one' ],
        [ 'X-Middle', 'keep' ],
        [ 'x-trace', 'two' ],
        [ 'X-Last', 'after' ],
    ],
);
my $response = Linux::Event::HTTP::Response->new(
    status => 201,
    headers => [
        [ 'X-First', 'before' ],
        [ 'Set-Cookie', 'a=1' ],
        [ 'X-Middle', 'keep' ],
        [ 'set-cookie', 'b=2' ],
        [ 'X-Last', 'after' ],
    ],
);

for my $method (@common) {
    ok($request->can($method), "Request provides Uniform method $method");
    ok($response->can($method), "Response provides Uniform method $method");
}

for my $method (qw(method target target_is_exact)) {
    ok($request->can($method), "Request provides Uniform request method $method");
}
for my $method (qw(status reason)) {
    ok($response->can($method), "Response provides Uniform response method $method");
}

is(ref($request->header_values('X-Trace')), 'ARRAY',
    'Request header_values always returns an array reference');
is_deeply($request->header_values('X-Trace'), [ 'one', 'two' ],
    'Request header_values preserves duplicate occurrence order');
is_deeply($request->header_values('Missing'), [],
    'Request absent header returns an empty array reference');

is(ref($response->header_values('Set-Cookie')), 'ARRAY',
    'Response header_values always returns an array reference');
is_deeply($response->header_values('Set-Cookie'), [ 'a=1', 'b=2' ],
    'Response preserves duplicate Set-Cookie occurrences without joining');
is_deeply($response->header_values('Missing'), [],
    'Response absent header returns an empty array reference');

$request->header('X-TRACE', 'replacement');
is($request->header_count, 4,
    'Request replacement removes duplicate occurrences');
is($request->header_name(1), 'X-TRACE',
    'Request replacement keeps first matching position and supplied spelling');
is($request->header_value(1), 'replacement',
    'Request replacement installs supplied value');
is($request->header_name(2), 'X-Middle',
    'Request replacement preserves inter-field order');

$response->header('SET-COOKIE', 'replacement');
is($response->header_count, 4,
    'Response replacement removes duplicate occurrences');
is($response->header_name(1), 'SET-COOKIE',
    'Response replacement keeps first matching position and supplied spelling');
is($response->header_name(2), 'X-Middle',
    'Response replacement preserves inter-field order');

ok($request->headers_are_lossless, 'Request reports lossless header representation');
ok($response->headers_are_lossless, 'Response reports lossless header representation');
ok($request->target_is_exact, 'Request reports exact request-target');
ok($request->is_mutable, 'new Request reports mutable');
ok($response->is_mutable, 'new Response reports mutable');
ok(!$request->has_buffered_body, 'Request without body has no buffered body');
ok(!$response->has_buffered_body, 'Response without body has no buffered body');

$request->body('');
$response->body('');
ok($request->has_buffered_body, 'explicit empty Request body is buffered');
ok($response->has_buffered_body, 'explicit empty Response body is buffered');
is($request->body, '', 'explicit empty Request body remains distinct from absent body');
is($response->body, '', 'explicit empty Response body remains distinct from absent body');

my $ok = eval { Linux::Event::HTTP::Request->new(method => 'GET', target => '/')->body(undef); 1 };
ok(!$ok, 'Request body setter rejects undef');
like($@, qr/defined scalar byte string/, 'Request undef body error is explicit');
$ok = eval { Linux::Event::HTTP::Response->new->body(undef); 1 };
ok(!$ok, 'Response body setter rejects undef');
like($@, qr/defined scalar byte string/, 'Response undef body error is explicit');

$request->version(undef);
$response->version(undef);
ok(!defined($request->version), 'Request can represent unknown HTTP version');
ok(!defined($response->version), 'Response can represent unknown HTTP version');

is($request->header_name($request->header_count), undef,
    'Request past-end header_name returns undef');
is($request->header_value($request->header_count), undef,
    'Request past-end header_value returns undef');
is($response->header_name($response->header_count), undef,
    'Response past-end header_name returns undef');
is($response->header_value($response->header_count), undef,
    'Response past-end header_value returns undef');

for my $message ($request, $response) {
    $ok = eval { $message->header_name(-1); 1 };
    ok(!$ok, 'negative header index is a programmer error');
    like($@, qr/non-negative integer/, 'negative index error is explicit');
    $ok = eval { $message->header_value('not-an-index'); 1 };
    ok(!$ok, 'non-integer header index is a programmer error');
    like($@, qr/non-negative integer/, 'non-integer index error is explicit');
}

$ok = eval { Linux::Event::HTTP::Response->new(status => 600); 1 };
ok(!$ok, 'Response rejects status above 599');
like($@, qr/100 and 599/, 'Response status range follows Uniform contract');

my $no_reason = Linux::Event::HTTP::Response->new(status => 404);
ok(!defined($no_reason->reason), 'Response does not synthesize a reason phrase');

my $wide = "\x{100}";
$ok = eval { Linux::Event::HTTP::Request->new(method => 'POST', target => '/', body => $wide); 1 };
ok(!$ok, 'Request body rejects wide characters');
like($@, qr/encode it to bytes first/, 'Request wide-body error describes byte contract');
$ok = eval { Linux::Event::HTTP::Response->new(headers => [ [ 'X-Test', $wide ] ]); 1 };
ok(!$ok, 'Response header value rejects wide characters');
like($@, qr/encode it to bytes first/, 'Response wide-header error describes byte contract');

my $local_request = Linux::Event::HTTP::Request->new(method => 'GET', target => '/');
my $local_response = Linux::Event::HTTP::Response->new;
$local_request->_mark_committed;
$local_response->_commit;
ok(!$local_request->is_mutable, 'committed Request reports immutable');
ok(!$local_response->is_mutable, 'committed Response reports immutable');
$ok = eval { $local_request->header('X-Test', 'x'); 1 };
ok(!$ok, 'committed Request mutator throws');
$ok = eval { $local_response->header('X-Test', 'x'); 1 };
ok(!$ok, 'committed Response mutator throws');

my $wire = join '',
    "GET /exact%2Ftarget?x=1 HTTP/1.1\r\n",
    "Host: example.test\r\n",
    "X-Dup: one\r\n",
    "X-Dup: two\r\n",
    "\r\n";
my $native = Linux::Event::HTTP::_HTTP1->parse_request($wire);
isa_ok($native, 'Linux::Event::HTTP::Request');
is($native->target, '/exact%2Ftarget?x=1',
    'native Request preserves exact wire request-target');
ok($native->target_is_exact, 'native Request reports exact target fidelity');
ok($native->headers_are_lossless, 'native Request reports lossless headers');
ok(!$native->is_mutable, 'native parsed Request is immutable');
ok(!$native->has_buffered_body, 'native parsed Request does not imply buffered body');
is_deeply($native->header_values('X-Dup'), [ 'one', 'two' ],
    'native Request public header_values follows Uniform arrayref contract');
is($native->header_name($native->header_count), undef,
    'native Request past-end indexed access returns undef');

for my $message ($request, $response) {
    for my $method (qw(send write respond receive parse serialize socket connection transaction stream retry redirect)) {
        ok(!$message->can($method), "message does not own transport/lifecycle method $method");
    }
}

done_testing;

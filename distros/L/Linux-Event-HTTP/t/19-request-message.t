use v5.36;
use strict;
use warnings;

use Test::More;
use Linux::Event::HTTP::Request;

my $request = Linux::Event::HTTP::Request->new(
    method  => 'POST',
    target  => '/items?x=1',
    headers => [
        [ 'Host', 'example.test' ],
        [ 'X-Test', 'one' ],
        [ 'X-Test', 'two' ],
        [ 'Content-Length', '5' ],
    ],
    body => 'hello',
);

isa_ok($request, 'Linux::Event::HTTP::Request');
is($request->method, 'POST', 'local request exposes method');
is($request->target, '/items?x=1', 'local request exposes target');
is($request->version, '1.1', 'local request defaults to HTTP version 1.1');
is($request->content_length, 5, 'local request exposes declared Content-Length');
is($request->body, 'hello', 'local request retains complete scalar body');
ok($request->has_buffered_body, 'scalar local request reports buffered body');
ok($request->is_complete, 'scalar local request body is complete');
ok($request->is_mutable, 'local request is mutable before commit');
ok($request->headers_are_lossless, 'local request preserves lossless headers');
ok($request->target_is_exact, 'local request target is exact');

is($request->header_count, 4, 'local request preserves header count');
is($request->header_name(0), 'Host', 'local request preserves header order and spelling');
is($request->header_value(2), 'two', 'local request exposes indexed values');
is_deeply(
    $request->header_values('x-test'),
    [ 'one', 'two' ],
    'local request preserves repeated fields',
);

$request->method('PUT')->target('/other')->version('1.0');
is($request->method, 'PUT', 'method is mutable before commit');
is($request->target, '/other', 'target is mutable before commit');
is($request->version, '1.0', 'version is mutable before commit');

$request->header('X-Test', 'replacement');
is_deeply(
    $request->header_values('X-Test'),
    [ 'replacement' ],
    'header setter replaces all same-name fields',
);
is($request->header_name(1), 'X-Test',
    'replacement remains at the first matching field position');

$request->add_header('X-Test', 'second');
is_deeply(
    $request->header_values('X-Test'),
    [ 'replacement', 'second' ],
    'add_header appends another field',
);

$request->remove_header('X-Test');
is_deeply(
    $request->header_values('X-Test'),
    [],
    'remove_header removes all same-name fields',
);

my $committed = Linux::Event::HTTP::Request->new(
    method => 'GET',
    target => '/',
);
$committed->_mark_committed;
ok(!$committed->is_mutable, 'committed local request reports immutable state');
my $ok = eval { $committed->target('/changed'); 1 };
ok(!$ok, 'committed local request is immutable');
like($@, qr/cannot change after .* committed/, 'commit mutation failure is clear');

$ok = eval {
    Linux::Event::HTTP::Request->new(method => 'BAD METHOD', target => '/');
    1;
};
ok(!$ok, 'invalid method is rejected');
like($@, qr/invalid request method/, 'invalid method error is clear');

$ok = eval {
    Linux::Event::HTTP::Request->new(method => 'GET', target => "/bad target");
    1;
};
ok(!$ok, 'invalid target is rejected');
like($@, qr/invalid request target/, 'invalid target error is clear');

$ok = eval {
    Linux::Event::HTTP::Request->new(
        method => 'GET',
        target => '/',
        headers => [ [ 'Bad Header', 'x' ] ],
    );
    1;
};
ok(!$ok, 'invalid header name is rejected');
like($@, qr/invalid header field name/, 'invalid header error is clear');

my $duplicate_length = Linux::Event::HTTP::Request->new(
    method => 'POST',
    target => '/',
    headers => [
        [ 'Content-Length', '3' ],
        [ 'Content-Length', '4' ],
    ],
);
$ok = eval { $duplicate_length->content_length; 1 };
ok(!$ok, 'conflicting local Content-Length values are rejected');
like($@, qr/conflicting Content-Length/, 'conflicting Content-Length error is clear');

done_testing;

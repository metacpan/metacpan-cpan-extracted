use v5.36;
use strict;
use warnings;

use Test::More;
use Linux::Event::HTTP::_HTTP1;

my $parser = 'Linux::Event::HTTP::_HTTP1';

is($parser->pico_version, '1.dev', 'vendored picohttpparser reports expected version');

my $head = join '',
    "GET /hello?x=1 HTTP/1.1\r\n",
    "Host: example.test\r\n",
    "X-Test: one\r\n",
    "X-Test: two\r\n",
    "X_Legal: underscore\r\n",
    "\r\n";
my $request = $head . 'BODY';

my $parsed = $parser->parse_request_offsets($request);
ok($parsed, 'complete request parses');

my ($consumed, $minor, $method_offset, $method_length,
    $target_offset, $target_length, $headers) = @$parsed;

is($consumed, length($head), 'parser reports only header bytes consumed');
is($minor, 1, 'HTTP/1.1 minor version parsed');
is(substr($request, $method_offset, $method_length), 'GET', 'method is an offset into original buffer');
is(substr($request, $target_offset, $target_length), '/hello?x=1', 'target is an offset into original buffer');
is(scalar @$headers, 4, 'header count parsed');

my @decoded = map {
    my ($name_offset, $name_length, $value_offset, $value_length) = @$_;
    [
        substr($request, $name_offset, $name_length),
        substr($request, $value_offset, $value_length),
    ]
} @$headers;

is_deeply(
    \@decoded,
    [
        [ 'Host',    'example.test' ],
        [ 'X-Test',  'one' ],
        [ 'X-Test',  'two' ],
        [ 'X_Legal', 'underscore' ],
    ],
    'header case, duplicates, underscores, and values remain slices of original buffer',
);

my $partial = substr($head, 0, 24);
is($parser->probe_request($partial), -2, 'partial request reports incomplete');
ok(!defined $parser->parse_request_offsets($partial), 'offset parser returns undef for incomplete request');
is(
    $parser->probe_request($head, length($partial)),
    length($head),
    'incremental parse accepts previous buffer length',
);

is(
    $parser->probe_request("GET / HTTP/1.1\r\nBad Header: value\r\n\r\n"),
    -1,
    'malformed header name is rejected',
);

is(
    $parser->probe_request("GET / HTTP/1.1\r\nX-Test: one\r\n two\r\n\r\n"),
    -1,
    'obsolete folded header is rejected by strict wrapper',
);

my $fold_error = eval {
    $parser->parse_request_offsets("GET / HTTP/1.1\r\nX-Test: one\r\n two\r\n\r\n");
    1;
};
ok(!$fold_error, 'offset parser rejects obsolete folded header');
like($@, qr/malformed HTTP\/1 request/, 'fold rejection uses malformed request error');

is($parser->probe_request($head, 0, 3), -1, 'header limit is enforced');
is($parser->probe_request($head, 0, 4), length($head), 'exact header limit is accepted');

my $second = "GET /second HTTP/1.1\r\nHost: example.test\r\n\r\n";
my $pipeline = $head . $second;
is(
    $parser->probe_request($pipeline),
    length($head),
    'pipelined buffer consumes only first request head',
);

my $pipeline_parsed = $parser->parse_request_offsets($pipeline);
is(
    substr($pipeline, $pipeline_parsed->[4], $pipeline_parsed->[5]),
    '/hello?x=1',
    'offset result still points into first pipelined request',
);

my $error = eval { $parser->parse_request_offsets($head, length($head) + 1); 1 };
ok(!$error, 'invalid incremental length is rejected');
like($@, qr/last_len exceeds buffer length/, 'incremental length error is clear');

$error = eval { $parser->probe_request($head, 0, 0); 1 };
ok(!$error, 'zero max_headers is rejected');
like($@, qr/max_headers must be between 1 and 256/, 'header limit validation error is clear');

$error = eval { $parser->probe_request($head, 0, 257); 1 };
ok(!$error, 'excessive max_headers is rejected');
like($@, qr/max_headers must be between 1 and 256/, 'maximum header bound error is clear');

done_testing;

use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::HTTP::_HTTP1 ();
use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::Response;

my $parser = 'Linux::Event::HTTP::_HTTP1';
my $native = 'Linux::Event::HTTP::_HTTP1';

my $get = $parser->parse_request(
    "GET / HTTP/1.1\r\nHost: example.test\r\n\r\n",
    0,
    100,
);

is(
    $native->build_default_final($get, 'hello'),
    "HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhello",
    'native builder emits default persistent HTTP/1.1 final response',
);

is(
    $native->build_default_final($get, undef),
    "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n",
    'undefined body is treated as an empty byte string',
);

my $number = 12345;
is(
    $native->build_default_final($get, $number),
    "HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\n12345",
    'non-PV scalar retains existing stringification behavior',
);

my $downgradable = "\x{e9}";
utf8::upgrade($downgradable);
ok(utf8::is_utf8($downgradable), 'downgradable test scalar starts UTF-8 flagged');
is(
    $native->build_default_final($get, $downgradable),
    "HTTP/1.1 200 OK\r\nContent-Length: 1\r\n\r\n\xe9",
    'downgradable UTF-8 scalar is emitted as bytes',
);
ok(
    utf8::is_utf8($downgradable),
    'native builder does not mutate caller UTF-8 flag while downgrading copy',
);

my $head = $parser->parse_request(
    "HEAD / HTTP/1.1\r\nHost: example.test\r\n\r\n",
    0,
    100,
);
is(
    $native->build_default_final($head, 'hello'),
    undef,
    'HEAD falls back to the general response path',
);

my $close = $parser->parse_request(
    "GET / HTTP/1.1\r\nHost: example.test\r\nConnection: close\r\n\r\n",
    0,
    100,
);
is(
    $native->build_default_final($close, 'hello'),
    undef,
    'non-persistent request falls back to the general response path',
);

my $ok = eval {
    $native->build_default_final($get, []);
    1;
};
ok(!$ok, 'reference body is rejected');
like($@, qr/body must be a scalar byte string/, 'reference body error is stable');

my $wide = "\x{100}";
$ok = eval {
    $native->build_default_final($get, $wide);
    1;
};
ok(!$ok, 'wide-character body is rejected');
like($@, qr/body contains wide characters/, 'wide-character body error is stable');

subtest 'scalar builder validates later headers before committing metadata' => sub {
    for my $bad (
        ['Content-Length', '5'], ['Transfer-Encoding', 'chunked'],
        ['Connection', 'close'], ['Bad Name', 'value'],
        ['X-Bad', "bad\r\nInjected: yes"], ['X-Missing'], 'not an array',
    ) {
        my $response = Linux::Event::HTTP::Response->_new_server_default($get);
        $response->header('Content-Type', 'text/plain');
        $response->body('hello');
        # Bypass the setter deliberately, leaving the fast-path marker intact.
        push @{$response->{headers}}, $bad;
        is($native->build_simple_scalar_final($get, $response, 'hello'), undef,
            'late malformed/framing header declines the fast path');
        ok(!$response->{committed}, 'decline does not commit the response');
        is(scalar @{$response->{headers}}, 2,
            'decline does not append generated Content-Length');
        pop @{$response->{headers}};
        $response->header('X-Second', 'two');
        is($native->build_simple_scalar_final($get, $response, 'hello'),
            "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nX-Second: two\r\n"
                . "Content-Length: 5\r\n\r\nhello",
            'corrected response emits all headers once in order');
        is($response->header('Content-Length'), '5',
            'generated framing remains visible through the public API');
    }
};

done_testing;

use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::Response;
use Linux::Event::HTTP::_HTTP1;
use Linux::Event::HTTP::_HTTP2;

{
    package T::HTTP2Controller;
    sub new ($class) { bless {}, $class }
}

subtest 'Request scheme and authority are protocol-neutral metadata' => sub {
    my $request = Linux::Event::HTTP::Request->new(
        method    => 'GET',
        target    => '/items?x=1',
        version   => '2',
        scheme    => 'https',
        authority => 'example.test:8443',
        headers   => [
            [ 'x-test', 'one' ],
        ],
    );

    is($request->scheme, 'https', 'local Request exposes explicit scheme');
    is($request->authority, 'example.test:8443',
        'local Request exposes explicit authority');

    $request->scheme('http')->authority('other.test');
    is($request->scheme, 'http', 'scheme is mutable before commit');
    is($request->authority, 'other.test', 'authority is mutable before commit');

    $request->scheme(undef)->authority(undef);
    ok(!defined($request->scheme), 'explicit undef clears scheme');
    ok(!defined($request->authority), 'explicit undef clears authority');
};

subtest 'HTTP/1 derives metadata without changing headers' => sub {
    my $origin = Linux::Event::HTTP::Request->new(
        method  => 'GET',
        target  => '/resource',
        headers => [ [ Host => 'origin.test:8080' ] ],
    );
    ok(!defined($origin->scheme),
        'origin-form HTTP/1 does not invent a scheme');
    is($origin->authority, 'origin.test:8080',
        'origin-form HTTP/1 derives authority from Host');
    is($origin->header_count, 1,
        'authority derivation does not change header list');

    my $absolute = Linux::Event::HTTP::Request->new(
        method => 'GET',
        target => 'https://absolute.test:444/path?q=1',
    );
    is($absolute->scheme, 'https',
        'absolute-form HTTP/1 derives scheme from target');
    is($absolute->authority, 'absolute.test:444',
        'absolute-form HTTP/1 derives authority from target');

    my $connect = Linux::Event::HTTP::Request->new(
        method => 'CONNECT',
        target => 'tunnel.test:443',
    );
    ok(!defined($connect->scheme),
        'CONNECT authority-form target does not invent a scheme');
    is($connect->authority, 'tunnel.test:443',
        'CONNECT authority-form target derives authority');

    my $wire = join '',
        "GET /native HTTP/1.1\r\n",
        "Host: native.test\r\n",
        "\r\n";
    my $native = Linux::Event::HTTP::_HTTP1->parse_request($wire);
    ok(!defined($native->scheme),
        'native HTTP/1 request leaves unavailable scheme undefined');
    is($native->authority, 'native.test',
        'native HTTP/1 request derives authority lazily from Host');
};

subtest 'HTTP/2 request pseudo-headers map into Request metadata' => sub {
    my $request = Linux::Event::HTTP::_HTTP2->request_from_headers(
        [
            [ ':method', 'POST' ],
            [ ':scheme', 'https' ],
            [ ':authority', 'api.test' ],
            [ ':path', '/items' ],
            [ 'content-type', 'application/json' ],
            [ 'x-trace', 'one' ],
            [ 'x-trace', 'two' ],
        ],
        end_stream => 0,
    );

    isa_ok($request, 'Linux::Event::HTTP::Request');
    is($request->method, 'POST', 'method maps from :method');
    is($request->scheme, 'https', 'scheme maps from :scheme');
    is($request->authority, 'api.test', 'authority maps from :authority');
    is($request->target, '/items', 'target maps from :path');
    is($request->version, '2', 'HTTP/2 Request reports version 2');
    ok(!$request->is_mutable, 'received HTTP/2 Request is committed');
    ok(!$request->is_complete, 'non-END_STREAM Request remains incomplete');
    is($request->header_count, 3,
        'pseudo-headers are excluded from ordinary header count');
    is_deeply($request->header_values('x-trace'), [ 'one', 'two' ],
        'ordinary duplicate headers remain lossless');
    ok(!defined($request->header('Host')),
        'authority mapping does not manufacture a Host field');

    $request->_mark_complete;
    ok($request->is_complete, 'protocol layer can complete received H2 Request');

    my $block = Linux::Event::HTTP::_HTTP2->request_headers(
        Linux::Event::HTTP::Request->new(
            method    => 'GET',
            target    => '/outbound',
            version   => '2',
            scheme    => 'https',
            authority => 'outbound.test',
            headers   => [
                [ 'X-Mixed-Case', 'value' ],
            ],
        ),
    );

    is_deeply(
        [ @$block[0 .. 3] ],
        [
            [ ':method', 'GET' ],
            [ ':scheme', 'https' ],
            [ ':authority', 'outbound.test' ],
            [ ':path', '/outbound' ],
        ],
        'outbound pseudo-header order is canonical',
    );
    is_deeply($block->[4], [ 'x-mixed-case', 'value' ],
        'outbound ordinary field names are lowercase on the wire');
};

subtest 'ordinary CONNECT maps authority-form target' => sub {
    my $request = Linux::Event::HTTP::_HTTP2->request_from_headers(
        [
            [ ':method', 'CONNECT' ],
            [ ':authority', 'example.test:443' ],
        ],
        end_stream => 1,
    );

    is($request->method, 'CONNECT', 'CONNECT method maps normally');
    is($request->target, 'example.test:443',
        'HTTP/2 CONNECT uses authority as protocol-neutral target');
    is($request->authority, 'example.test:443',
        'HTTP/2 CONNECT preserves authority');
    ok(!defined($request->scheme),
        'ordinary HTTP/2 CONNECT has no scheme');
    ok($request->is_complete,
        'END_STREAM CONNECT request is input-complete');

    is_deeply(
        Linux::Event::HTTP::_HTTP2->request_headers(
            Linux::Event::HTTP::Request->new(
                method    => 'CONNECT',
                target    => 'other.test:443',
                version   => '2',
                authority => 'other.test:443',
            ),
        ),
        [
            [ ':method', 'CONNECT' ],
            [ ':authority', 'other.test:443' ],
        ],
        'outbound ordinary CONNECT omits :scheme and :path',
    );
};

subtest 'HTTP/2 responses map :status without a reason phrase' => sub {
    my $response = Linux::Event::HTTP::_HTTP2->response_from_headers(
        [
            [ ':status', '204' ],
            [ 'x-result', 'ok' ],
        ],
        end_stream => 1,
    );

    isa_ok($response, 'Linux::Event::HTTP::Response');
    is($response->status, 204, 'status maps from :status');
    is($response->version, '2', 'HTTP/2 Response reports version 2');
    ok(!defined($response->reason),
        'HTTP/2 Response does not invent a reason phrase');
    is($response->header('x-result'), 'ok',
        'ordinary response field is preserved');
    is($response->header_count, 1,
        ':status is excluded from ordinary response fields');
    ok($response->is_complete, 'END_STREAM Response is complete');

    my $out = Linux::Event::HTTP::_HTTP2->response_headers(
        Linux::Event::HTTP::Response->new(
            status  => 201,
            reason  => 'Created but not on H2 wire',
            version => '2',
            headers => [
                [ 'X-Result', 'yes' ],
            ],
        ),
    );
    is_deeply(
        $out,
        [
            [ ':status', '201' ],
            [ 'x-result', 'yes' ],
        ],
        'outbound H2 response omits reason phrase and lowercases fields',
    );
};

subtest 'HTTP/2 field rules are enforced at mapper boundary' => sub {
    my $ok = eval {
        Linux::Event::HTTP::_HTTP2->request_from_headers(
            [
                [ ':method', 'GET' ],
                [ 'x-first', '1' ],
                [ ':path', '/' ],
                [ ':scheme', 'https' ],
                [ ':authority', 'example.test' ],
            ],
        );
        1;
    };
    ok(!$ok, 'pseudo-header after regular field is rejected');
    like($@, qr/pseudo-header follows a regular field/,
        'pseudo-header ordering error is explicit');

    $ok = eval {
        Linux::Event::HTTP::_HTTP2->request_from_headers(
            [
                [ ':method', 'GET' ],
                [ ':scheme', 'https' ],
                [ ':authority', 'example.test' ],
                [ ':path', '/' ],
                [ 'Connection', 'close' ],
            ],
        );
        1;
    };
    ok(!$ok, 'uppercase HTTP/2 field name is rejected');
    like($@, qr/field names must be lowercase/,
        'lowercase field rule is explicit');

    $ok = eval {
        Linux::Event::HTTP::_HTTP2->request_from_headers(
            [
                [ ':method', 'GET' ],
                [ ':scheme', 'https' ],
                [ ':authority', 'example.test' ],
                [ ':path', '/' ],
                [ 'connection', 'close' ],
            ],
        );
        1;
    };
    ok(!$ok, 'connection-specific H2 field is rejected');
    like($@, qr/forbids connection-specific field/,
        'connection-specific field error is explicit');

    $ok = eval {
        Linux::Event::HTTP::_HTTP2->request_from_headers(
            [
                [ ':method', 'CONNECT' ],
                [ ':authority', 'example.test:443' ],
                [ ':protocol', 'websocket' ],
            ],
        );
        1;
    };
    ok(!$ok, 'extended CONNECT is not accidentally accepted');
    like($@, qr/unsupported pseudo-header ':protocol'/,
        'extended CONNECT deferral is explicit');
};

subtest 'one HTTP/2 request stream maps to one Transaction' => sub {
    my $controller = T::HTTP2Controller->new;
    my $tx = Linux::Event::HTTP::_HTTP2->server_transaction_from_headers(
        [
            [ ':method', 'GET' ],
            [ ':scheme', 'https' ],
            [ ':authority', 'tx.test' ],
            [ ':path', '/transaction' ],
        ],
        $controller,
        end_stream => 1,
    );

    isa_ok($tx, 'Linux::Event::HTTP::Transaction');
    is($tx->state, 'active', 'server H2 Transaction starts active');
    is($tx->request->version, '2', 'Transaction owns H2 Request');
    is($tx->request->authority, 'tx.test',
        'Transaction Request keeps H2 authority metadata');
    isa_ok($tx->response, 'Linux::Event::HTTP::Response');
    is($tx->response->version, '2',
        'server H2 Transaction creates H2 Response');
    is($tx->response->status, 200,
        'server H2 Transaction keeps ordinary default status');
};

done_testing;

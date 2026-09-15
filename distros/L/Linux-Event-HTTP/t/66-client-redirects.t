use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Client::Operation;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

my $loop = Linux::Event::Loop->new;
my %body;
my %seen;

my $server2 = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    on_request => sub ($conn, $req, $res) {
        $seen{cross} = {
            host          => $req->header('Host'),
            authorization => $req->header('Authorization'),
            cookie        => $req->header('Cookie'),
            keep          => $req->header('X-Keep'),
            method        => $req->method,
        };
        $res->body("cross-ok\n");
    },
);

my $server1 = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    on_request => sub ($conn, $req, $res) {
        $seen{$req->target} = {
            method => $req->method,
            host   => $req->header('Host'),
        };

        if ($req->target eq '/start') {
            $res->status(302);
            $res->header('Location', '/final');
            $res->body("intermediate\n");
            return;
        }

        if ($req->target eq '/final') {
            $res->body("final\n");
            return;
        }

        if ($req->target eq '/after303') {
            $res->body($req->method . " after303\n");
            return;
        }

        if ($req->target eq '/after302') {
            $res->body($req->method . " after302\n");
            return;
        }

        if ($req->target eq '/cross') {
            $res->status(302);
            $res->header(
                'Location',
                'http://127.0.0.1:' . $server2->port . '/landing',
            );
            $res->body("cross redirect\n");
            return;
        }

        if ($req->target eq '/loop-a') {
            $res->status(302);
            $res->header('Location', '/loop-b');
            $res->body("a\n");
            return;
        }

        if ($req->target eq '/loop-b') {
            $res->status(302);
            $res->header('Location', '/loop-a');
            $res->body("b\n");
            return;
        }

        if ($req->target eq '/no-follow') {
            $res->status(302);
            $res->header('Location', '/final');
            $res->add_header('Location', '/other');
            $res->body("stay here\n");
            return;
        }
    },
    on_body => sub ($conn, $req, $res, $bytes) {
        $body{$req->target} .= $bytes;
    },
    on_request_end => sub ($conn, $req, $res) {
        if ($req->target eq '/see-other') {
            $res->status(303);
            $res->header('Location', '/after303');
            $res->body("see other\n");
            return;
        }

        if ($req->target eq '/post-found') {
            $res->status(302);
            $res->header('Location', '/after302');
            $res->body("found\n");
            return;
        }

        if ($req->target eq '/preserve') {
            $res->status(307);
            $res->header('Location', '/preserved');
            $res->body("preserve\n");
            return;
        }

        if ($req->target eq '/preserved') {
            $res->body(
                $req->method . ' preserved='
                . ($body{'/preserved'} // '') . "\n"
            );
            return;
        }

        if ($req->target eq '/stream-preserve') {
            $res->status(307);
            $res->header('Location', '/preserved-stream');
            $res->body("stream preserve\n");
            return;
        }
    },
);

my $base = 'http://127.0.0.1:' . $server1->port;
my $client = Linux::Event::HTTP::Client->new(loop => $loop);

is($client->max_redirects, 5, 'Client follows at most five redirects by default');

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 5,
    on_timer => sub ($timer) {
        die "client redirect test timed out\n";
    },
);

my $finished = 0;
my $finish = sub {
    return if ++$finished < 8;
    $guard->cancel;
    $client->close;
    $server1->close;
    $server2->close;
    $loop->stop;
};

my $response_calls = 0;
my $redirect_calls = 0;
my $body1 = '';

my $op1;
$op1 = $client->get(
    "$base/start#frag",
    on_redirect => sub ($op, $tx, $res, $next_url) {
        ++$redirect_calls;
        is($res->status, 302, 'on_redirect receives redirect Response');
        like($next_url, qr{/final#frag\z},
            'relative Location is resolved and inherited fragment is retained');
    },
    on_response => sub ($tx, $res) {
        ++$response_calls;
        is($res->status, 200, 'on_response sees only final redirected Response');
    },
    on_body => sub ($tx, $res, $bytes) {
        $body1 .= $bytes;
    },
    on_complete => sub ($tx) {
        is($body1, "final\n",
            'intermediate redirect body is not delivered through final on_body');
        is($op1->redirect_count, 1, 'Operation records one followed redirect');
        is($op1->transaction_count, 2,
            'redirect creates a distinct second Transaction');
        my @tx = $op1->transactions;
        isa_ok($tx[0], 'Linux::Event::HTTP::Transaction');
        isa_ok($tx[1], 'Linux::Event::HTTP::Transaction');
        is($tx[0]->response->status, 302,
            'first Transaction retains redirect Response');
        is($tx[1], $tx, 'final callback receives final Transaction');
        ok($op1->is_complete, 'redirect Operation completes after final hop');
        $finish->();
    },
    on_error => sub ($tx, $error) {
        die "basic redirect failed: $error\n";
    },
);

isa_ok($op1, 'Linux::Event::HTTP::Client::Operation');
is($op1->request->target, '/start',
    'Operation delegates Request access to current Transaction');

my $op303;
$op303 = $client->post(
    "$base/see-other",
    body => 'abc',
    buffer_body => 1024,
    on_complete => sub ($tx) {
        my @tx = $op303->transactions;
        is($tx[0]->request->method, 'POST', '303 starts from POST');
        is($tx[1]->request->method, 'GET', '303 redirects POST to GET');
        is($tx[1]->request->body, undef, '303 redirected GET has no Request body');
        is($tx->response->body, "GET after303\n",
            '303 final Response can still use bounded buffering');
        is($body{'/see-other'}, 'abc', 'server receives original 303 POST body');
        ok(!defined($body{'/after303'}),
            '303 redirected GET does not replay original body');
        $finish->();
    },
    on_error => sub ($tx, $error) {
        die "303 redirect failed: $error\n";
    },
);

my $op302;
$op302 = $client->post(
    "$base/post-found",
    body => 'xyz',
    buffer_body => 1024,
    on_complete => sub ($tx) {
        my @tx = $op302->transactions;
        is($tx[1]->request->method, 'GET',
            '302 follows prevailing POST-to-GET redirect behavior');
        is($tx[1]->request->body, undef,
            '302 POST-to-GET redirect drops request body');
        is($tx->response->body, "GET after302\n",
            '302 POST redirect reaches final GET resource');
        $finish->();
    },
    on_error => sub ($tx, $error) {
        die "302 POST redirect failed: $error\n";
    },
);

my $op307;
$op307 = $client->post(
    "$base/preserve",
    body => 'keep',
    buffer_body => 1024,
    on_complete => sub ($tx) {
        my @tx = $op307->transactions;
        is($tx[1]->request->method, 'POST', '307 preserves Request method');
        is($tx[1]->request->body, 'keep', '307 replays complete scalar body');
        is($body{'/preserve'}, 'keep', 'server receives initial 307 Request body');
        is($body{'/preserved'}, 'keep', 'server receives replayed 307 Request body');
        is($tx->response->body, "POST preserved=keep\n",
            '307 preserved request reaches final resource');
        $finish->();
    },
    on_error => sub ($tx, $error) {
        die "307 redirect failed: $error\n";
    },
);

my $op_cross;
$op_cross = $client->get(
    "$base/cross",
    headers => [
        [ Host => 'virtual.example.test' ],
        [ Authorization => 'Bearer secret' ],
        [ Cookie => 'session=secret' ],
        [ 'X-Keep' => 'yes' ],
    ],
    buffer_body => 1024,
    on_complete => sub ($tx) {
        is($seen{cross}{authorization}, undef,
            'cross-origin redirect strips Authorization');
        is($seen{cross}{cookie}, undef,
            'cross-origin redirect strips Cookie');
        is($seen{cross}{keep}, 'yes',
            'cross-origin redirect preserves ordinary application headers');
        is(
            $seen{cross}{host},
            '127.0.0.1:' . $server2->port,
            'redirect regenerates Host for target origin',
        );
        is($tx->response->body, "cross-ok\n",
            'cross-origin redirect reaches second server');
        $finish->();
    },
    on_error => sub ($tx, $error) {
        die "cross-origin redirect failed: $error\n";
    },
);

my $loop_redirects = 0;
my $op_loop;
$op_loop = $client->get(
    "$base/loop-a",
    max_redirects => 1,
    on_redirect => sub ($op, $tx, $res, $next_url) {
        ++$loop_redirects;
    },
    on_complete => sub ($tx) {
        die "redirect limit operation unexpectedly completed\n";
    },
    on_error => sub ($tx, $error) {
        like($error, qr/maximum redirect count exceeded/,
            'redirect limit produces clear terminal error');
        is($loop_redirects, 1,
            'on_redirect runs only for the hop that is actually followed');
        is($op_loop->transaction_count, 2,
            'redirect limit error retains both completed Transactions');
        ok($op_loop->state eq 'error', 'redirect limit marks Operation error');
        $finish->();
    },
);

my $nofollow_body = '';
my $op_nofollow;
$op_nofollow = $client->get(
    "$base/no-follow",
    max_redirects => 0,
    on_response => sub ($tx, $res) {
        is($res->status, 302,
            'max_redirects zero exposes redirect as final Response');
        is_deeply(
            $res->header_values('Location'),
            [ '/final', '/other' ],
            'disabled redirect following does not interpret duplicate Location fields',
        );
    },
    on_body => sub ($tx, $res, $bytes) {
        $nofollow_body .= $bytes;
    },
    on_complete => sub ($tx) {
        is($nofollow_body, "stay here\n",
            'disabled redirect following delivers 3xx response body normally');
        is($op_nofollow->transaction_count, 1,
            'disabled redirect following creates one Transaction');
        $finish->();
    },
    on_error => sub ($tx, $error) {
        die "no-follow request failed: $error\n";
    },
);

my $op_stream;
$op_stream = $client->post(
    "$base/stream-preserve",
    stream_body => {},
    on_complete => sub ($tx) {
        die "streaming 307 operation unexpectedly completed\n";
    },
    on_error => sub ($tx, $error) {
        like($error, qr/streaming Request body.*not replayable/,
            'method-preserving redirect refuses non-replayable stream');
        is($op_stream->transaction_count, 1,
            'non-replayable stream does not create unsafe second Transaction');
        ok($op_stream->state eq 'error',
            'non-replayable redirect marks Operation error');
        $finish->();
    },
);
$op_stream->request_body->complete('streamed');

$loop->run;

is($response_calls, 1, 'on_response ran only for final response');
is($redirect_calls, 1, 'on_redirect ran exactly once for basic redirect');

done_testing;

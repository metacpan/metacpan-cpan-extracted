use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

my $loop = Linux::Event::Loop->new;
my $state = {
    connection => {},
};

my $server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    data => $state,
    on_request => sub ($conn, $req, $res) {
        $state->{connection}{$req->target} = refaddr($conn);

        if ($req->target eq '/fixed') {
            $res->header('Content-Type', 'text/plain');
            $res->body('hello');
            return;
        }

        if ($req->target eq '/chunked') {
            my $body = $conn->transaction->response_body;
            $body->write('abc');
            $body->complete('def');
            return;
        }

        if ($req->target eq '/close') {
            my $body = $conn->transaction->response_body;
            $body->write('close-');
            $body->complete('body');
            return;
        }

        if ($req->target eq '/too-big-fixed') {
            $res->body('0123456789');
            return;
        }

        if ($req->target eq '/too-big-chunked') {
            my $body = $conn->transaction->response_body;
            $body->write('abc');
            $body->complete('def');
            return;
        }

        $res->status(404);
        $res->body('missing');
    },
);

my $client = Linux::Event::HTTP::Client->new(
    loop => $loop,
    connect_timeout => 2,
);

my $base = 'http://127.0.0.1:' . $server->port;

my $ok = eval {
    $client->get("$base/fixed", buffer_body => 0);
    1;
};
ok(!$ok, 'zero buffer_body limit is rejected');
like($@, qr/buffer_body must be greater than zero/,
    'zero limit rejection is clear');

$ok = eval {
    $client->get(
        "$base/fixed",
        buffer_body => 16,
        on_body => sub ($tx, $res, $bytes) { },
    );
    1;
};
ok(!$ok, 'buffer_body and on_body are mutually exclusive');
like($@, qr/buffer_body cannot be combined with on_body/,
    'buffer/on_body conflict is clear');

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 5,
    on_timer => sub ($timer) {
        die "buffered client response test timed out\n";
    },
);

my $finish = sub {
    $guard->cancel;
    $client->close;
    $server->close;
    $loop->stop;
};

my $run_too_big_chunked;
my $run_too_big_fixed;
my $run_close;
my $run_head;
my $run_chunked;

$run_too_big_chunked = sub {
    my $saw_response = 0;
    $client->get(
        "$base/too-big-chunked",
        buffer_body => 5,
        on_response => sub ($tx, $res) {
            $saw_response++;
            is($res->body, undef,
                'unknown-length buffered body is not exposed before completion');
        },
        on_complete => sub ($tx) {
            die "oversize chunked response unexpectedly completed\n";
        },
        on_error => sub ($tx, $error) {
            is($saw_response, 1,
                'on_response runs before unknown-size buffer overflow');
            ok($tx->is_terminal && !$tx->is_complete,
                'unknown-size buffer overflow terminates Transaction as error');
            like($error, qr/exceeds buffer_body limit of 5 bytes/,
                'unknown-size overflow reports configured bound');
            is($tx->response->body, undef,
                'failed buffered response does not expose a partial body');
            isnt(
                $state->{connection}{'/too-big-fixed'},
                $state->{connection}{'/too-big-chunked'},
                'connection closed after fixed-size overflow is not reused',
            );
            $finish->();
        },
    );
};

$run_too_big_fixed = sub {
    my $saw_response = 0;
    $client->get(
        "$base/too-big-fixed",
        buffer_body => 5,
        on_response => sub ($tx, $res) {
            $saw_response++;
            is($res->content_length, 10,
                'known oversized response exposes validated Content-Length');
            is($res->body, undef,
                'known oversized response has not accumulated a body');
        },
        on_complete => sub ($tx) {
            die "oversize fixed response unexpectedly completed\n";
        },
        on_error => sub ($tx, $error) {
            is($saw_response, 1,
                'on_response runs before known-size buffer rejection');
            like($error, qr/exceeds buffer_body limit of 5 bytes/,
                'known-size overflow reports configured bound');
            ok(defined($tx->response),
                'Transaction retains parsed Response after buffer-limit error');
            $run_too_big_chunked->();
        },
    );
};

$run_close = sub {
    $client->get(
        "$base/close",
        version => '1.0',
        buffer_body => 32,
        on_complete => sub ($tx) {
            is($tx->response->body, 'close-body',
                'close-delimited HTTP/1.0 body buffers through EOF');
            ok($tx->response->is_complete,
                'close-delimited buffered Response is complete at EOF');
            $run_too_big_fixed->();
        },
        on_error => sub ($tx, $error) {
            die "close-delimited buffering failed: $error\n";
        },
    );
};

$run_head = sub {
    $client->head(
        "$base/fixed",
        buffer_body => 16,
        on_complete => sub ($tx) {
            is($tx->response->body, '',
                'bodyless HEAD response buffers as an empty scalar');
            is($tx->response->content_length, 5,
                'HEAD still exposes representation Content-Length');
            $run_close->();
        },
        on_error => sub ($tx, $error) {
            die "HEAD buffering failed: $error\n";
        },
    );
};

$run_chunked = sub {
    $client->get(
        "$base/chunked",
        buffer_body => 16,
        on_response => sub ($tx, $res) {
            is($res->body, undef,
                'chunked body remains unavailable while message is incomplete');
        },
        on_complete => sub ($tx) {
            is($tx->response->body, 'abcdef',
                'chunked transfer framing is removed before buffering');
            ok($tx->response->is_complete,
                'buffered chunked Response is complete');
            $run_head->();
        },
        on_error => sub ($tx, $error) {
            die "chunked buffering failed: $error\n";
        },
    );
};

$client->get(
    "$base/fixed",
    buffer_body => 16,
    on_response => sub ($tx, $res) {
        is($res->status, 200, 'buffered request still exposes response head early');
        is($res->body, undef,
            'fixed-length body is unavailable before complete message boundary');
        ok(!$res->is_complete,
            'Response remains incomplete while buffered bytes are arriving');
    },
    on_complete => sub ($tx) {
        my $res = $tx->response;
        is($res->body, 'hello',
            'fixed-length response body is available as one scalar on completion');
        ok($res->is_complete, 'buffered fixed Response is complete');
        ok($tx->is_complete, 'buffered fixed Transaction completes normally');

        my $mutable = eval {
            $res->header('X-Late', 'no');
            1;
        };
        ok(!$mutable,
            'buffering does not make received Response metadata mutable');
        like($@, qr/metadata cannot change after message commit/,
            'received metadata remains committed after buffering');

        $run_chunked->();
    },
    on_error => sub ($tx, $error) {
        die "fixed buffered response failed: $error\n";
    },
);

$loop->run;

done_testing;

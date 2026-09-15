use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);

use Linux::Event::HTTP::Client::Connection;
use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

my $loop = Linux::Event::Loop->new;
my $state = {
    server_connections => [],
    post_body          => '',
    response_body      => {},
    response_status    => {},
    response_incomplete_at_head => {},
    response_read_only => {},
    complete_message   => {},
    complete_tx        => {},
    active_match       => {},
};

my $server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    data => $state,
    on_request => sub ($conn, $req, $res) {
        push @{$state->{server_connections}}, refaddr($conn);

        if ($req->target eq '/post') {
            return;
        }

        if ($req->target eq '/one') {
            $res->header('X-Server', 'one');
            $res->body("one\n");
            return;
        }

        if ($req->target eq '/chunked') {
            $res->header('Content-Type', 'text/plain');
            my $body = $conn->transaction->response_body;
            $body->write("two\n");
            $body->complete("three\n");
            return;
        }

        if ($req->target eq '/discard') {
            $res->body("discarded\n");
            return;
        }

        if ($req->target eq '/close') {
            $res->header('Connection', 'close');
            $res->body("bye\n");
            return;
        }

        die "unexpected target: " . $req->target;
    },
    on_body => sub ($conn, $req, $res, $bytes) {
        $state->{post_body} .= $bytes if $req->target eq '/post';
    },
    on_request_end => sub ($conn, $req, $res) {
        $res->body("posted\n") if $req->target eq '/post';
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 3,
    on_timer => sub ($timer) {
        die "client connection integration test timed out\n";
    },
);

my $client = Linux::Event::HTTP::Client::Connection->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $server->port,
);

my $bad_host = Linux::Event::HTTP::Request->new(
    method => 'GET',
    target => '/',
);
my $ok = eval { $client->request($bad_host); 1 };
ok(!$ok, 'HTTP/1.1 request without Host is rejected before a Transaction starts');
like($@, qr/requires exactly one Host/, 'missing Host failure is clear');
ok(!defined $client->transaction, 'rejected request does not occupy the connection');

sub request_for ($method, $target, %extra) {
    return Linux::Event::HTTP::Request->new(
        method  => $method,
        target  => $target,
        headers => [ [ Host => 'example.test' ] ],
        %extra,
    );
}

my ($start_one, $start_chunked, $start_discard, $start_close);

$start_close = sub {
    my $request = request_for('GET', '/close');
    $client->request(
        $request,
        on_response => sub ($tx, $res) {
            $state->{response_status}{close} = $res->status;
            $state->{response_incomplete_at_head}{close}
                = $res->is_complete ? 0 : 1;
            $state->{active_match}{close}
                = refaddr($client->transaction) == refaddr($tx) ? 1 : 0;
        },
        on_body => sub ($tx, $res, $bytes) {
            $state->{response_body}{close} .= $bytes;
        },
        on_complete => sub ($tx) {
            $state->{complete_message}{close} = $tx->response->is_complete ? 1 : 0;
            $state->{complete_tx}{close} = $tx->is_complete ? 1 : 0;
            $state->{closed_before_complete_callback} = $client->is_closed ? 1 : 0;
            $guard->cancel;
            $server->close;
            $loop->stop;
        },
        on_error => sub ($tx, $error) {
            die "close request failed: $error\n";
        },
    );
};

$start_discard = sub {
    my $request = request_for('GET', '/discard');
    $client->request(
        $request,
        on_response => sub ($tx, $res) {
            $state->{response_status}{discard} = $res->status;
        },
        on_complete => sub ($tx) {
            $state->{discard_body_value} = $tx->response->body;
            $state->{complete_message}{discard} = $tx->response->is_complete ? 1 : 0;
            $state->{complete_tx}{discard} = $tx->is_complete ? 1 : 0;
            $start_close->();
        },
        on_error => sub ($tx, $error) {
            die "discard request failed: $error\n";
        },
    );
};

$start_chunked = sub {
    my $request = request_for('GET', '/chunked');
    $client->request(
        $request,
        on_response => sub ($tx, $res) {
            $state->{response_status}{chunked} = $res->status;
            $state->{response_incomplete_at_head}{chunked}
                = $res->is_complete ? 0 : 1;
            $state->{chunked_transfer} = $res->header('Transfer-Encoding');
        },
        on_body => sub ($tx, $res, $bytes) {
            $state->{response_body}{chunked} .= $bytes;
        },
        on_complete => sub ($tx) {
            $state->{complete_message}{chunked} = $tx->response->is_complete ? 1 : 0;
            $state->{complete_tx}{chunked} = $tx->is_complete ? 1 : 0;
            $start_discard->();
        },
        on_error => sub ($tx, $error) {
            die "chunked request failed: $error\n";
        },
    );
};

$start_one = sub {
    my $request = request_for('GET', '/one');
    $client->request(
        $request,
        on_response => sub ($tx, $res) {
            $state->{response_status}{one} = $res->status;
            $state->{response_incomplete_at_head}{one}
                = $res->is_complete ? 0 : 1;
            $state->{server_header} = $res->header('X-Server');
            $state->{active_match}{one}
                = refaddr($client->transaction) == refaddr($tx) ? 1 : 0;
            my $mutable = eval { $res->header('X-Client', 'no'); 1 };
            $state->{response_read_only}{one} = $mutable ? 0 : 1;
        },
        on_body => sub ($tx, $res, $bytes) {
            $state->{response_body}{one} .= $bytes;
        },
        on_complete => sub ($tx) {
            $state->{complete_message}{one} = $tx->response->is_complete ? 1 : 0;
            $state->{complete_tx}{one} = $tx->is_complete ? 1 : 0;
            $state->{buffered_one_body} = $tx->response->body;
            $start_chunked->();
        },
        on_error => sub ($tx, $error) {
            die "one request failed: $error\n";
        },
    );
};

my $post = request_for('POST', '/post', body => 'abc');
my $post_tx = $client->request(
    $post,
    on_response => sub ($tx, $res) {
        $state->{response_status}{post} = $res->status;
        $state->{response_incomplete_at_head}{post}
            = $res->is_complete ? 0 : 1;
    },
    on_body => sub ($tx, $res, $bytes) {
        $state->{response_body}{post} .= $bytes;
    },
    on_complete => sub ($tx) {
        $state->{complete_message}{post} = $tx->response->is_complete ? 1 : 0;
        $state->{complete_tx}{post} = $tx->is_complete ? 1 : 0;
        $start_one->();
    },
    on_error => sub ($tx, $error) {
        die "post request failed: $error\n";
    },
);

is($post->content_length, 3,
    'client adds Content-Length to a complete scalar Request body');
is($post_tx->request, $post, 'returned Transaction owns the outgoing Request');
is($client->transaction, $post_tx, 'Connection exposes the active client Transaction');

my $busy = eval {
    $client->request(request_for('GET', '/too-soon'));
    1;
};
ok(!$busy, 'second in-flight request is rejected instead of pipelined');
like($@, qr/already active/, 'single in-flight Transaction rule is clear');

$loop->run;

is($state->{post_body}, 'abc', 'server receives client scalar request body');
is($state->{response_body}{post}, "posted\n", 'client receives fixed-length POST response body');
is($state->{response_body}{one}, "one\n", 'client receives fixed-length response body incrementally');
is($state->{response_body}{chunked}, "two\nthree\n",
    'client decodes HTTP/1 chunked transfer coding before on_body');
is($state->{response_body}{close}, "bye\n",
    'client receives final Connection-close response body');

is($state->{server_header}, 'one', 'client exposes response headers');
like($state->{chunked_transfer} // '', qr/chunked/i,
    'chunked wire response remains visible in response metadata');
ok($state->{response_read_only}{one}, 'received Response metadata is committed/read-only');
ok($state->{response_incomplete_at_head}{one},
    'received Response is incomplete when only the final response head is available');
ok($state->{response_incomplete_at_head}{chunked},
    'chunked Response is incomplete at on_response');

for my $name (qw(post one chunked discard close)) {
    is($state->{response_status}{$name}, 200, "$name response status is 200");
    ok($state->{complete_message}{$name}, "$name Response reaches message completion");
    ok($state->{complete_tx}{$name}, "$name Transaction reaches successful completion");
}

ok(!defined $state->{buffered_one_body},
    'incoming fixed-length response body is not implicitly buffered on Response');
ok(!defined $state->{discard_body_value},
    'response body is drained rather than accumulated when on_body is absent');
ok($state->{active_match}{one}, 'on_response sees the active Transaction on Connection');
ok($state->{active_match}{close}, 'final on_response still sees the active Transaction');
ok($state->{closed_before_complete_callback},
    'Connection: close makes the client connection non-reusable before on_complete');

my %server_connection = map { $_ => 1 } @{$state->{server_connections}};
is(scalar(keys %server_connection), 1,
    'all sequential client Transactions reused one persistent server connection');

ok($client->is_closed, 'client connection is closed after Connection: close response');
ok(!defined $client->transaction, 'client connection has no active Transaction after completion');

done_testing;

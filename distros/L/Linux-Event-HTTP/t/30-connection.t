use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::HTTP::Server::Connection;

{
    package T::HTTPConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';
    use Scalar::Util qw(refaddr);

    sub on_request ($self, $request, $response) {
        push @{$self->data->{targets}}, $request->target;
        push @{$self->data->{responses}}, $response;
        push @{$self->data->{request_state_refs}},
            refaddr($self->{_http_request_state});
        push @{$self->data->{body_done_on_request}},
            $self->{_http_request_state}{body_done} ? 1 : 0;

        my $transaction = $self->transaction;
        push @{$self->data->{paired}},
            $transaction
            && $transaction->request == $request
            && $transaction->response == $response ? 1 : 0;

        $response->status(200);
        $response->header('Content-Type', 'text/plain');

        if ($request->target eq '/one') {
            $response->header('Content-Length', 4);
            my $body = $transaction->response_body;
            push @{$self->data->{write_status}}, $body->write('on');
            $body->complete("e\n");
        } else {
            $response->body("two\n");
        }
    }

    sub on_request_end ($self, $request, $response) {
        push @{$self->data->{request_end_targets}}, $request->target;
        push @{$self->data->{body_done_on_request_end}},
            $self->{_http_request_state}{body_done} ? 1 : 0;
    }
}

my $loop = Linux::Event::Loop->new;
my $state = {
    targets      => [],
    responses    => [],
    paired       => [],
    write_status => [],
    request_state_refs       => [],
    body_done_on_request     => [],
    request_end_targets      => [],
    body_done_on_request_end => [],
    response     => '',
    eof          => 0,
};

my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        class => 'T::HTTPConnection',
        data  => $state,
    },
);

my $client = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    on_ready => sub ($stream) {
        $stream->write(
            "GET /one HTTP/1.1\r\n" .
            "Host: example.test\r\n" .
            "\r\n" .
            "GET /two HTTP/1.1\r\n" .
            "Host: example.test\r\n" .
            "Connection: close\r\n" .
            "\r\n"
        );
    },
    on_data => sub ($stream, $bytes) {
        $state->{response} .= $bytes;
    },
    on_eof => sub ($stream) {
        $state->{eof} = 1;
        $stream->close;
        $listener->close;
        $loop->stop;
    },
    on_error => sub ($stream, $error) {
        die "HTTP test client failed: $error\n";
    },
);

$loop->run;

is_deeply(
    $state->{targets},
    [ '/one', '/two' ],
    'one accepted HTTP connection dispatches pipelined requests in order',
);
is_deeply(
    $state->{paired},
    [ 1, 1 ],
    'Connection Transaction pairs each Request and Response',
);
is(
    $state->{request_state_refs}[0],
    $state->{request_state_refs}[1],
    'bodyless requests reuse per-connection transaction state',
);
is_deeply(
    $state->{body_done_on_request},
    [ 0, 0 ],
    'bodyless request state remains pending during on_request',
);
is_deeply(
    $state->{request_end_targets},
    [ '/one', '/two' ],
    'bodyless fast path dispatches on_request_end in request order',
);
is_deeply(
    $state->{body_done_on_request_end},
    [ 1, 1 ],
    'bodyless request state is complete during on_request_end',
);
ok($state->{write_status}[0], 'response body producer exposes Stream backpressure status');
ok(
    $state->{responses}[0]->is_complete && $state->{responses}[1]->is_complete,
    'each Response message body is complete when its transaction completes',
);
my $mutation_ok = eval { $state->{responses}[0]->status(201); 1 };
ok(!$mutation_ok, 'completed Response metadata is immutable after message commit');
like($@, qr/cannot change/, 'completed metadata rejection is clear');
ok($state->{eof}, 'Connection close request drains responses then ends stream');

my $wire = $state->{response};
my @status = $wire =~ /HTTP\/1\.1 200 OK\r\n/g;
is(scalar @status, 2, 'two HTTP responses were serialized on one connection');

like(
    $wire,
    qr/HTTP\/1\.1 200 OK\r\nContent-Type: text\/plain\r\nContent-Length: 4\r\n\r\none\n/s,
    'fixed-length incremental body emits without buffering it whole',
);
like(
    $wire,
    qr/HTTP\/1\.1 200 OK\r\nContent-Type: text\/plain\r\nContent-Length: 4\r\nConnection: close\r\n\r\ntwo\n\z/s,
    'scalar body adds Content-Length and drains close response',
);

{
    package T::DeferredHTTPConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';
    use Linux::Event::Kernel::Timer;

    sub on_request ($self, $request, $response) {
        my $transaction = $self->transaction;
        $self->data->{request} = $request;
        $self->data->{response_object} = $response;
        $self->data->{transaction} = $transaction;

        Linux::Event::Kernel::Timer->new(
            loop  => $self->loop,
            after => 0.02,
            data  => {
                connection  => $self,
                transaction => $transaction,
                response    => $response,
            },
            on_timer => sub ($timer) {
                my $data = $timer->data;
                my $connection = $data->{connection};
                my $transaction = $data->{transaction};
                my $response = $data->{response};

                $connection->data->{paused_before_response}
                    = $connection->is_read_paused ? 1 : 0;
                $response->body("later\n");
                $transaction->send_response;
            },
        );
        return;
    }
}

$loop = Linux::Event::Loop->new;
my $deferred = {
    response => '',
};

$listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        class => 'T::DeferredHTTPConnection',
        data  => $deferred,
    },
);

$client = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    on_ready => sub ($stream) {
        $stream->write(
            "GET /later HTTP/1.1\r\n" .
            "Host: example.test\r\n" .
            "Connection: close\r\n" .
            "\r\n"
        );
    },
    on_data => sub ($stream, $bytes) {
        $deferred->{response} .= $bytes;
    },
    on_eof => sub ($stream) {
        $stream->close;
        $listener->close;
        $loop->stop;
    },
    on_error => sub ($stream, $error) {
        die "deferred HTTP test client failed: $error\n";
    },
);

$loop->run;

ok(
    $deferred->{paused_before_response},
    'Connection pauses reads while its Response is pending',
);
is(
    $deferred->{request}->target,
    '/later',
    'deferred callback retains stable Request object',
);
is(
    $deferred->{transaction}->request,
    $deferred->{request},
    'deferred Transaction retains its Request',
);
is(
    $deferred->{transaction}->response,
    $deferred->{response_object},
    'deferred Transaction retains its Response',
);
ok(
    $deferred->{response_object}->is_complete,
    'deferred Response message records scalar body completion',
);
ok(
    $deferred->{transaction}->is_complete,
    'explicit send_response completes the deferred Transaction',
);
like(
    $deferred->{response},
    qr/Content-Length: 6\r\nConnection: close\r\n\r\nlater\n\z/s,
    'deferred Response body is sent explicitly through its Transaction',
);

my $removed_ok = eval {
    Linux::Event::HTTP::Server::Connection->new(
        on_request => sub { },
        on_request_final => sub { return "old\n" },
    );
    1;
};
ok(!$removed_ok, 'direct Connection rejects removed on_request_final option');
like($@, qr/on_request_final was removed/, 'Connection gives migration guidance');

done_testing;

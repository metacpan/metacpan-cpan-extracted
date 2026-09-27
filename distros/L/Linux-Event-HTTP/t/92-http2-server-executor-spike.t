use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);

BEGIN {
    eval {
        require Net::HTTP2::nghttp2;
        Net::HTTP2::nghttp2->VERSION('0.011');
        require Net::HTTP2::nghttp2::Session;
        1;
    } or plan skip_all => 'Net::HTTP2::nghttp2 is not installed';

    Net::HTTP2::nghttp2->available
        or plan skip_all => 'nghttp2 library is not available';
}

use Linux::Event::HTTP::_HTTP2::Server;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

sub flush_client ($stream, $session) {
    while ($session->want_write) {
        my $bytes = $session->mem_send;
        last if !defined($bytes) || $bytes eq '';
        $stream->write($bytes);
    }
    return;
}

my $loop = Linux::Event::Loop->new;
my $server_executor;
my %server_executor_by_fd;
my @server_transactions;
my %server_body;
my @delayed_timers;

my $server_state = {
    errors                  => [],
    current_transaction_ok  => 1,
    request_end_count       => 0,
    stream_initial_accepted => undef,
    stream_drain_hits       => 0,
};

my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        on_ready => sub ($stream) {
            my $executor;
            $executor = Linux::Event::HTTP::_HTTP2::Server->new(
                stream => $stream,
                on_request => sub ($h2, $req, $res) {
                    my $tx = $h2->transaction;
                    $server_state->{current_transaction_ok} &&=
                        defined($tx) && refaddr($tx->request) == refaddr($req);

                    push @server_transactions, $tx;
                    my $id = refaddr($tx);
                    $server_body{$id} = '';

                    if ($req->target =~ m{\A/scalar/}) {
                        $res->header('x-kind', 'scalar');
                        $res->body('scalar:' . $req->target);
                        return;
                    }

                    if ($req->target eq '/stream') {
                        $res->header('x-kind', 'stream');
                        my $body;
                        $body = $tx->response_body(
                            on_drain => sub ($producer) {
                                ++$server_state->{stream_drain_hits};
                                $producer->complete('done');
                            },
                        );
                        $server_state->{stream_initial_accepted} =
                            $body->write('x' x 100_000) ? 1 : 0;
                        return;
                    }

                    if ($req->target eq '/delayed') {
                        $res->header('x-kind', 'delayed');
                        my $timer;
                        $timer = Linux::Event::Kernel::Timer->new(
                            loop => $loop,
                            after => 0.01,
                            on_timer => sub ($self) {
                                $res->body('later');
                                $tx->send_response;
                                $timer = undef;
                            },
                        );
                        push @delayed_timers, $timer;
                        return;
                    }

                    if ($req->target eq '/post') {
                        $res->header('x-kind', 'post');
                        return;
                    }

                    die 'unexpected HTTP/2 request target ' . $req->target;
                },
                on_body => sub ($h2, $req, $res, $bytes) {
                    my $tx = $h2->transaction;
                    $server_state->{current_transaction_ok} &&=
                        defined($tx) && refaddr($tx->request) == refaddr($req);
                    $server_body{refaddr($tx)} .= $bytes;
                },
                on_request_end => sub ($h2, $req, $res) {
                    ++$server_state->{request_end_count};
                    my $tx = $h2->transaction;
                    $server_state->{current_transaction_ok} &&=
                        defined($tx) && refaddr($tx->request) == refaddr($req);

                    if ($req->target eq '/post') {
                        $res->body('post:' . $server_body{refaddr($tx)});
                    }
                },
                on_error => sub ($h2, $stream_id, $error) {
                    push @{$server_state->{errors}},
                        "stream $stream_id: $error";
                },
            );
            $server_executor = $executor;
            $server_executor_by_fd{$stream->fd} = $executor;
        },
        on_data => sub ($stream, $bytes) {
            my $executor = $server_executor_by_fd{$stream->fd}
                or die "HTTP/2 server executor is not ready\n";
            $executor->input($bytes);
        },
        on_drain => sub ($stream) {
            my $executor = $server_executor_by_fd{$stream->fd} or return;
            $executor->transport_drain;
        },
        on_error => sub ($stream, $error) {
            push @{$server_state->{errors}}, "transport: $error";
            $loop->stop;
        },
        on_close => sub ($stream) {
            my $executor = delete $server_executor_by_fd{$stream->fd};
            $executor->close if $executor;
        },
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 10,
    on_timer => sub ($timer) {
        die "HTTP/2 server executor integration test timed out\n";
    },
);

my $client_state = {
    expected => 6,
    closed   => 0,
    path     => {},
    response => {},
    errors   => [],
};

my $client_session;
my $client = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    on_ready => sub ($stream) {
        $client_session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_begin_headers => sub ($stream_id, $type, $flags) {
                    $client_state->{response}{$stream_id} //= {
                        headers => {},
                        body    => '',
                    };
                    return 0;
                },
                on_header => sub ($stream_id, $name, $value, $flags) {
                    my $response = $client_state->{response}{$stream_id} //= {
                        headers => {},
                        body    => '',
                    };
                    if ($name eq ':status') {
                        $response->{status} = $value;
                    } else {
                        $response->{headers}{lc $name} = $value;
                    }
                    return 0;
                },
                on_data_chunk_recv => sub ($stream_id, $data, $flags) {
                    $client_state->{response}{$stream_id}{body} .= $data;
                    return 0;
                },
                on_stream_close => sub ($stream_id, $error_code) {
                    $client_state->{response}{$stream_id}{close_error} =
                        $error_code;
                    ++$client_state->{closed};

                    if ($client_state->{closed} == $client_state->{expected}) {
                        $guard->cancel;
                        $stream->close if !$stream->is_closed;
                        $listener->close;
                        $loop->stop;
                    }
                    return 0;
                },
                on_error => sub ($lib_error, $message) {
                    push @{$client_state->{errors}},
                        "nghttp2 $lib_error: $message";
                    return 0;
                },
            },
        );

        $client_session->send_connection_preface(
            max_concurrent_streams => 100,
        );

        for my $number (1 .. 3) {
            my $path = "/scalar/$number";
            my $id = $client_session->submit_request(
                method    => 'GET',
                path      => $path,
                scheme    => 'http',
                authority => 'executor.test',
            );
            $client_state->{path}{$id} = $path;
        }

        my $post = $client_session->submit_request(
            method    => 'POST',
            path      => '/post',
            scheme    => 'http',
            authority => 'executor.test',
            body      => 'request-body',
        );
        $client_state->{path}{$post} = '/post';

        my $streaming = $client_session->submit_request(
            method    => 'GET',
            path      => '/stream',
            scheme    => 'http',
            authority => 'executor.test',
        );
        $client_state->{path}{$streaming} = '/stream';

        my $delayed = $client_session->submit_request(
            method    => 'GET',
            path      => '/delayed',
            scheme    => 'http',
            authority => 'executor.test',
        );
        $client_state->{path}{$delayed} = '/delayed';

        flush_client($stream, $client_session);
    },
    on_data => sub ($stream, $bytes) {
        my $consumed = $client_session->mem_recv($bytes);
        die "HTTP/2 client did not consume complete input\n"
            if !defined($consumed) || $consumed != length($bytes);
        flush_client($stream, $client_session);
    },
    on_error => sub ($stream, $error) {
        push @{$client_state->{errors}}, "transport: $error";
        $loop->stop;
    },
);

$loop->run;

is_deeply($server_state->{errors}, [], 'server executor reports no errors');
is_deeply($client_state->{errors}, [], 'client reports no HTTP/2 errors');
ok($server_state->{current_transaction_ok},
    'executor transaction() is callback-scoped to the current H2 stream');
is($server_state->{request_end_count}, 6,
    'request-end callback runs once for every multiplexed request');
is(scalar(@server_transactions), 6,
    'one Transaction is created for each HTTP/2 request stream');

my %seen_tx = map { refaddr($_) => 1 } @server_transactions;
is(scalar(keys %seen_tx), 6, 'all stream Transactions are distinct');
for my $tx (@server_transactions) {
    ok($tx->is_complete, 'closed HTTP/2 stream leaves Transaction complete');
    is($tx->request->version, '2', 'Transaction Request reports HTTP/2');
    is($tx->request->authority, 'executor.test',
        'Transaction Request preserves authority metadata');
    is($tx->response->version, '2', 'Transaction Response reports HTTP/2');
}

is($server_state->{stream_initial_accepted}, 0,
    'large streaming response applies Body::Stream backpressure');
cmp_ok($server_state->{stream_drain_hits}, '>=', 1,
    'HTTP/2 data-provider progress triggers Body::Stream on_drain');

for my $stream_id (sort { $a <=> $b } keys %{$client_state->{path}}) {
    my $path = $client_state->{path}{$stream_id};
    my $response = $client_state->{response}{$stream_id};

    is($response->{close_error}, 0,
        "$path stream closes without HTTP/2 error");
    is($response->{status}, '200', "$path receives status 200");

    if ($path =~ m{\A/scalar/}) {
        is($response->{headers}{'x-kind'}, 'scalar',
            "$path preserves scalar response header");
        is($response->{body}, "scalar:$path",
            "$path receives independent scalar body");
    } elsif ($path eq '/post') {
        is($response->{headers}{'x-kind'}, 'post',
            'POST preserves response header');
        is($response->{body}, 'post:request-body',
            'POST DATA reaches on_body and on_request_end');
    } elsif ($path eq '/stream') {
        is($response->{headers}{'x-kind'}, 'stream',
            'streaming response preserves header');
        is(length($response->{body}), 100_004,
            'streaming response delivers complete 100 KiB plus final bytes');
        is(substr($response->{body}, 0, 8), 'xxxxxxxx',
            'streaming response begins with produced data');
        is(substr($response->{body}, -4), 'done',
            'streaming response completes from on_drain callback');
    } elsif ($path eq '/delayed') {
        is($response->{headers}{'x-kind'}, 'delayed',
            'delayed response preserves header');
        is($response->{body}, 'later',
            'retained Transaction sends response from later Timer callback');
    }
}

is($server_executor->stream_count, 0,
    'executor releases all stream state after completion');


{
    package T::HTTP2EndStream;
    sub is_closed ($self) { 0 }
    sub end ($self) {
        ++$self->{end_count};
        return $self;
    }

    package T::HTTP2EndSession;
    sub want_read ($self)  { !!$self->{want_read} }
    sub want_write ($self) { !!$self->{want_write} }

    package main;

    my $peer_stream = bless { end_count => 0 }, 'T::HTTP2EndStream';
    my $peer_session = bless {
        want_read  => 1,
        want_write => 0,
    }, 'T::HTTP2EndSession';
    my $peer_executor = bless {
        stream            => $peer_stream,
        session           => $peer_session,
        streams           => {},
        closed            => 0,
        transport_blocked => 0,
        transport_ending  => 0,
        peer_goaway       => 0,
    }, 'Linux::Event::HTTP::_HTTP2::Server';

    is($peer_executor->_on_frame_recv({ type => 7 }), 0,
        'peer GOAWAY frame is accepted');
    $peer_executor->_maybe_end_transport;
    is($peer_stream->{end_count}, 1,
        'peer GOAWAY gracefully ends transport after active streams drain');
    ok($peer_executor->{transport_ending},
        'peer GOAWAY marks graceful transport ending');

    my $fatal_stream = bless { end_count => 0 }, 'T::HTTP2EndStream';
    my $fatal_session = bless {
        want_read  => 0,
        want_write => 0,
    }, 'T::HTTP2EndSession';
    my $fatal_executor = bless {
        stream            => $fatal_stream,
        session           => $fatal_session,
        streams           => {},
        closed            => 0,
        transport_blocked => 0,
        transport_ending  => 0,
        peer_goaway       => 0,
    }, 'Linux::Event::HTTP::_HTTP2::Server';

    $fatal_executor->_maybe_end_transport;
    is($fatal_stream->{end_count}, 1,
        'completed nghttp2 session gracefully ends transport');

    my $live_stream = bless { end_count => 0 }, 'T::HTTP2EndStream';
    my $live_session = bless {
        want_read  => 1,
        want_write => 0,
    }, 'T::HTTP2EndSession';
    my $live_executor = bless {
        stream            => $live_stream,
        session           => $live_session,
        streams           => {},
        closed            => 0,
        transport_blocked => 0,
        transport_ending  => 0,
        peer_goaway       => 0,
    }, 'Linux::Event::HTTP::_HTTP2::Server';

    $live_executor->_maybe_end_transport;
    is($live_stream->{end_count}, 0,
        'live nghttp2 session keeps transport open');
}

done_testing;

use v5.36;
use strict;
use warnings;

use Test::More;

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

use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::_HTTP2::Client;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

use constant {
    H2_DATA       => 0,
    H2_HEADERS    => 1,
    H2_END_STREAM => 0x1,
};

sub flush_session ($stream, $session) {
    while ($session->want_write) {
        my $bytes = $session->mem_send;
        last if !defined($bytes) || $bytes eq '';
        $stream->write($bytes);
    }
    return;
}

my $loop = Linux::Event::Loop->new;
my %server_session;
my %server_request;

my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        on_ready => sub ($stream) {
            my $session;
            $session = Net::HTTP2::nghttp2::Session->new_server(
                callbacks => {
                    on_begin_headers => sub ($stream_id, $type, $flags) {
                        $server_request{$stream_id} = {
                            headers => [],
                            body    => '',
                            replied => 0,
                        };
                        return 0;
                    },
                    on_header => sub ($stream_id, $name, $value, $flags) {
                        my $state = $server_request{$stream_id};
                        push @{$state->{headers}}, [ $name, $value ];
                        $state->{$name} = $value
                            if substr($name, 0, 1) eq ':';
                        return 0;
                    },
                    on_data_chunk_recv => sub ($stream_id, $data, $flags) {
                        $server_request{$stream_id}{body} .= $data;
                        return 0;
                    },
                    on_frame_recv => sub ($frame) {
                        my $stream_id = $frame->{stream_id} // 0;
                        return 0 if !$stream_id;
                        return 0 if !(($frame->{flags} // 0) & H2_END_STREAM);
                        return 0 if ($frame->{type} // -1) != H2_HEADERS
                            && ($frame->{type} // -1) != H2_DATA;

                        my $state = $server_request{$stream_id} or return 0;
                        return 0 if $state->{replied}++;

                        my $path = $state->{':path'} // '';
                        my ($kind, $body);
                        if ($path =~ m{\A/scalar/}) {
                            $kind = 'scalar';
                            $body = "reply:$path";
                        } elsif ($path eq '/post') {
                            $kind = 'post';
                            $body = 'post:' . $state->{body};
                        } elsif ($path eq '/buffer') {
                            $kind = 'buffer';
                            $body = 'b' x 16_384;
                        } elsif ($path eq '/onbody') {
                            $kind = 'onbody';
                            $body = 'o' x 16_384;
                        } elsif ($path eq '/upload-stream') {
                            $kind = 'upload-stream';
                            $body = 'upload:' . length($state->{body});
                        } else {
                            die "unexpected raw server path '$path'\n";
                        }

                        $session->submit_response(
                            $stream_id,
                            status => 200,
                            headers => [
                                [ 'x-kind', $kind ],
                            ],
                            body => $body,
                        );
                        return 0;
                    },
                },
            );

            $server_session{$stream->fd} = $session;
            $session->send_connection_preface(
                max_concurrent_streams => 100,
            );
            flush_session($stream, $session);
        },
        on_data => sub ($stream, $bytes) {
            my $session = $server_session{$stream->fd}
                or die "raw HTTP/2 server session is not ready\n";
            my $consumed = $session->mem_recv($bytes);
            die "raw HTTP/2 server did not consume complete input\n"
                if !defined($consumed) || $consumed != length($bytes);
            flush_session($stream, $session);
        },
        on_close => sub ($stream) {
            delete $server_session{$stream->fd};
        },
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 10,
    on_timer => sub ($timer) {
        die "HTTP/2 client executor integration test timed out\n";
    },
);

my $state = {
    expected                => 7,
    complete                => 0,
    errors                  => [],
    result                  => {},
    transactions            => [],
    upload_initial_accepted => undef,
    upload_drain_hits       => 0,
};

my $executor;
my $client_stream = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    on_ready => sub ($stream) {
        $executor = Linux::Event::HTTP::_HTTP2::Client->new(
            stream => $stream,
        );

        my $start_request = sub ($path, %option) {
            my $result = $state->{result}{$path} = {
                body => '',
            };
            my $request = Linux::Event::HTTP::Request->new(
                method    => delete($option{method}) // 'GET',
                target    => $path,
                version   => '2',
                scheme    => 'http',
                authority => 'client-executor.test',
                (exists($option{body}) ? (body => delete($option{body})) : ()),
            );

            my $tx = $executor->request(
                $request,
                (exists($option{stream_body})
                    ? (stream_body => delete($option{stream_body}))
                    : ()),
                (exists($option{buffer_body})
                    ? (buffer_body => delete($option{buffer_body}))
                    : ()),
                on_response => sub ($transaction, $response) {
                    $result->{status} = $response->status;
                    $result->{kind} = $response->header('x-kind');
                },
                (delete($option{capture_body})
                    ? (on_body => sub ($transaction, $response, $bytes) {
                        $result->{body} .= $bytes;
                    })
                    : ()),
                on_complete => sub ($transaction) {
                    $result->{complete} = 1;
                    if ($path eq '/buffer') {
                        $result->{body} = $transaction->response->body;
                    }
                    ++$state->{complete};
                    if ($state->{complete} == $state->{expected}) {
                        $guard->cancel;
                        $stream->close if !$stream->is_closed;
                        $listener->close;
                        $loop->stop;
                    }
                },
                on_error => sub ($transaction, $error) {
                    push @{$state->{errors}}, "$path: $error";
                },
            );
            die 'unused request test option: ' . join(', ', sort keys %option)
                if %option;

            push @{$state->{transactions}}, $tx;
            return $tx;
        };

        $start_request->('/scalar/1', capture_body => 1);
        $start_request->('/scalar/2', capture_body => 1);
        $start_request->(
            '/post',
            method => 'POST',
            body => 'payload',
            capture_body => 1,
        );
        $start_request->(
            '/buffer',
            buffer_body => 20_000,
        );
        $start_request->('/onbody', capture_body => 1);
        $start_request->('/scalar/3', capture_body => 1);

        my $upload_tx;
        $upload_tx = $start_request->(
            '/upload-stream',
            method => 'POST',
            stream_body => {
                on_drain => sub ($body) {
                    ++$state->{upload_drain_hits};
                    $body->complete('done');
                },
            },
            capture_body => 1,
        );
        my $producer = $upload_tx->request_body;
        $state->{upload_initial_accepted} =
            $producer->write('u' x 100_000) ? 1 : 0;
    },
    on_data => sub ($stream, $bytes) {
        my $consumed = $executor->input($bytes);
        die "HTTP/2 client executor did not consume complete input\n"
            if $consumed != length($bytes);
    },
    on_drain => sub ($stream) {
        $executor->transport_drain if $executor;
    },
    on_error => sub ($stream, $error) {
        push @{$state->{errors}}, "transport: $error";
        $loop->stop;
    },
    on_close => sub ($stream) {
        $executor->close if $executor;
    },
);

$loop->run;

is_deeply($state->{errors}, [], 'client executor reports no errors');
is($state->{complete}, 7, 'all concurrent Client Transactions complete');
is(scalar(@{$state->{transactions}}), 7,
    'each HTTP/2 request returns its own Transaction');
for my $tx (@{$state->{transactions}}) {
    ok($tx->is_complete, 'HTTP/2 client Transaction completes independently');
    is($tx->request->version, '2', 'client Transaction Request reports HTTP/2');
    is($tx->response->version, '2', 'client Transaction Response reports HTTP/2');
}

for my $path (qw(/scalar/1 /scalar/2 /scalar/3)) {
    my $result = $state->{result}{$path};
    is($result->{status}, 200, "$path receives status 200");
    is($result->{kind}, 'scalar', "$path receives its response header");
    is($result->{body}, "reply:$path", "$path receives its response body");
}

is($state->{result}{'/post'}{kind}, 'post',
    'scalar POST receives post response');
is($state->{result}{'/post'}{body}, 'post:payload',
    'scalar POST body crosses HTTP/2 DATA');

is($state->{result}{'/buffer'}{kind}, 'buffer',
    'buffered response receives response header');
is(length($state->{result}{'/buffer'}{body}), 16_384,
    'buffer_body attaches complete bounded H2 response body');
is(substr($state->{result}{'/buffer'}{body}, 0, 8), 'bbbbbbbb',
    'buffered H2 response retains exact bytes');

is($state->{result}{'/onbody'}{kind}, 'onbody',
    'on_body response receives response header');
is(length($state->{result}{'/onbody'}{body}), 16_384,
    'on_body receives complete H2 DATA body');
is(substr($state->{result}{'/onbody'}{body}, 0, 8), 'oooooooo',
    'on_body H2 response retains exact bytes');

is($state->{upload_initial_accepted}, 0,
    'large streaming upload applies Body::Stream backpressure');
cmp_ok($state->{upload_drain_hits}, '>=', 1,
    'streaming upload receives on_drain as H2 flow credit advances');
is($state->{result}{'/upload-stream'}{kind}, 'upload-stream',
    'streaming upload receives response header');
is($state->{result}{'/upload-stream'}{body}, 'upload:100004',
    'streaming Request body resumes and completes through nghttp2');


{
    package T::HTTP2ClientEndStream;
    sub is_closed ($self) { 0 }
    sub end ($self) {
        ++$self->{end_count};
        return $self;
    }

    package T::HTTP2ClientEndSession;
    sub want_read ($self)  { !!$self->{want_read} }
    sub want_write ($self) { !!$self->{want_write} }

    package main;

    my $goaway_stream = bless {
        end_count => 0,
    }, 'T::HTTP2ClientEndStream';
    my $goaway_session = bless {
        want_read  => 1,
        want_write => 0,
    }, 'T::HTTP2ClientEndSession';
    my $goaway_executor = bless {
        stream            => $goaway_stream,
        session           => $goaway_session,
        streams           => {},
        draining          => 0,
        closed            => 0,
        transport_blocked => 0,
        transport_ending  => 0,
    }, 'Linux::Event::HTTP::_HTTP2::Client';

    is($goaway_executor->_on_frame_recv({ type => 7 }), 0,
        'client accepts peer GOAWAY frame');
    ok($goaway_executor->draining,
        'peer GOAWAY marks client executor draining');
    $goaway_executor->_maybe_end_transport;
    is($goaway_stream->{end_count}, 1,
        'drained GOAWAY client connection ends transport gracefully');
    ok($goaway_executor->{transport_ending},
        'drained GOAWAY client marks graceful transport ending');

    my $live_stream = bless {
        end_count => 0,
    }, 'T::HTTP2ClientEndStream';
    my $live_session = bless {
        want_read  => 1,
        want_write => 0,
    }, 'T::HTTP2ClientEndSession';
    my $live_executor = bless {
        stream            => $live_stream,
        session           => $live_session,
        streams           => {},
        draining          => 0,
        closed            => 0,
        transport_blocked => 0,
        transport_ending  => 0,
    }, 'Linux::Event::HTTP::_HTTP2::Client';

    $live_executor->_maybe_end_transport;
    is($live_stream->{end_count}, 0,
        'ordinary reusable H2 client connection remains open');
}

done_testing;

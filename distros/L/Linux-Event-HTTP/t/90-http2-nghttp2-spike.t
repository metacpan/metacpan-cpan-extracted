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

sub make_server_session ($stream, $state) {
    my $session;
    $session = Net::HTTP2::nghttp2::Session->new_server(
        callbacks => {
            on_begin_headers => sub ($stream_id, $frame_type, $flags) {
                $state->{request}{$stream_id} //= {
                    headers => [],
                    body    => '',
                };
                return 0;
            },
            on_header => sub ($stream_id, $name, $value, $flags) {
                my $request = $state->{request}{$stream_id} //= {
                    headers => [],
                    body    => '',
                };
                push @{$request->{headers}}, [ $name, $value ];
                $request->{$name} = $value if substr($name, 0, 1) eq ':';
                return 0;
            },
            on_data_chunk_recv => sub ($stream_id, $data, $flags) {
                $state->{request}{$stream_id}{body} .= $data;
                return 0;
            },
            on_frame_recv => sub ($frame) {
                my $type = $frame->{type};
                my $flags = $frame->{flags};
                my $stream_id = $frame->{stream_id};

                return 0 if !$stream_id;
                return 0 if !($flags & H2_END_STREAM);
                return 0 if $type != H2_HEADERS && $type != H2_DATA;
                return 0 if $state->{responded}{$stream_id}++;

                my $request = $state->{request}{$stream_id};
                my $path = $request->{':path'} // '';
                my $body = $request->{body} // '';

                if ($path eq '/deferred') {
                    my $ready = 0;
                    $session->submit_response(
                        $stream_id,
                        status => 200,
                        headers => [
                            [ 'content-type', 'text/plain' ],
                            [ 'x-spike', 'deferred' ],
                        ],
                        body => sub ($id, $max_length) {
                            return undef if !$ready;
                            return ('later', 1);
                        },
                    );
                    # mem_recv() will return to the Stream callback, which
                    # performs the flush after nghttp2 leaves this callback.

                    my $timer;
                    $timer = Linux::Event::Kernel::Timer->new(
                        loop => $stream->loop,
                        after => 0.01,
                        on_timer => sub ($self) {
                            $ready = 1;
                            $session->resume_stream($stream_id);
                            flush_session($stream, $session);
                            $timer = undef;
                        },
                    );
                    $state->{timer}{$stream_id} = $timer;
                    return 0;
                }

                $session->submit_response(
                    $stream_id,
                    status => 200,
                    headers => [
                        [ 'content-type', 'text/plain' ],
                        [ 'x-spike', 'scalar' ],
                    ],
                    body => join(':', $path, $body),
                );
                return 0;
            },
            on_stream_close => sub ($stream_id, $error_code) {
                ++$state->{server_closed};
                delete $state->{timer}{$stream_id};
                return 0;
            },
        },
    );

    $session->send_connection_preface(
        max_concurrent_streams => 100,
    );
    return $session;
}

sub make_client_session ($stream, $state, $loop, $listener) {
    my $session;
    $session = Net::HTTP2::nghttp2::Session->new_client(
        callbacks => {
            on_begin_headers => sub ($stream_id, $frame_type, $flags) {
                $state->{response}{$stream_id} //= {
                    headers => [],
                    body    => '',
                };
                return 0;
            },
            on_header => sub ($stream_id, $name, $value, $flags) {
                my $response = $state->{response}{$stream_id} //= {
                    headers => [],
                    body    => '',
                };
                push @{$response->{headers}}, [ $name, $value ];
                $response->{$name} = $value if substr($name, 0, 1) eq ':';
                $response->{header}{lc $name} = $value if substr($name, 0, 1) ne ':';
                return 0;
            },
            on_data_chunk_recv => sub ($stream_id, $data, $flags) {
                $state->{response}{$stream_id}{body} .= $data;
                return 0;
            },
            on_frame_recv => sub ($frame) {
                return 0;
            },
            on_stream_close => sub ($stream_id, $error_code) {
                $state->{closed}{$stream_id} = $error_code;
                ++$state->{client_closed};

                if ($state->{client_closed} == $state->{expected}) {
                    $stream->close if !$stream->is_closed;
                    $listener->close;
                    $loop->stop;
                }
                return 0;
            },
        },
    );

    $session->send_connection_preface(
        max_concurrent_streams => 100,
    );
    return $session;
}

my $loop = Linux::Event::Loop->new;
my $server_state = {
    request       => {},
    responded     => {},
    timer         => {},
    server_closed => 0,
};

my %server_session;

my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        on_ready => sub ($stream) {
            my $session = make_server_session($stream, $server_state);
            $server_session{$stream->fd} = $session;
            flush_session($stream, $session);
        },
        on_data => sub ($stream, $bytes) {
            my $session = $server_session{$stream->fd}
                or die "server HTTP/2 session is not ready\n";
            my $consumed = $session->mem_recv($bytes);
            die "server HTTP/2 session did not consume complete input\n"
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
    after => 5,
    on_timer => sub ($timer) {
        die "HTTP/2 nghttp2 integration spike timed out\n";
    },
);

my $client_state = {
    expected      => 9,
    response      => {},
    closed        => {},
    client_closed => 0,
    path_by_id    => {},
};

my $client_session;

my $client = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    on_ready => sub ($stream) {
        $client_session = make_client_session(
            $stream, $client_state, $loop, $listener,
        );

        for my $number (1 .. 7) {
            my $path = "/concurrent/$number";
            my $stream_id = $client_session->submit_request(
                method    => 'GET',
                path      => $path,
                scheme    => 'http',
                authority => 'spike.test',
                headers   => [
                    [ 'x-request-number', "$number" ],
                ],
            );
            $client_state->{path_by_id}{$stream_id} = $path;
        }

        my $post_id = $client_session->submit_request(
            method    => 'POST',
            path      => '/body',
            scheme    => 'http',
            authority => 'spike.test',
            headers   => [
                [ 'content-type', 'text/plain' ],
            ],
            body      => 'request-body',
        );
        $client_state->{path_by_id}{$post_id} = '/body';

        my $deferred_id = $client_session->submit_request(
            method    => 'GET',
            path      => '/deferred',
            scheme    => 'http',
            authority => 'spike.test',
        );
        $client_state->{path_by_id}{$deferred_id} = '/deferred';

        flush_session($stream, $client_session);
    },
    on_data => sub ($stream, $bytes) {
        die "client HTTP/2 session is not ready\n" if !$client_session;
        my $consumed = $client_session->mem_recv($bytes);
        die "client HTTP/2 session did not consume complete input\n"
            if !defined($consumed) || $consumed != length($bytes);
        flush_session($stream, $client_session);
    },
);

$loop->run;
$guard->cancel;

is($client_state->{client_closed}, 9,
    'all nine concurrent HTTP/2 streams closed');
is($server_state->{server_closed}, 9,
    'server observed all nine stream closures');

for my $stream_id (sort { $a <=> $b } keys %{$client_state->{path_by_id}}) {
    my $path = $client_state->{path_by_id}{$stream_id};
    my $response = $client_state->{response}{$stream_id};

    is($client_state->{closed}{$stream_id}, 0,
        "$path stream closed without HTTP/2 error");
    is($response->{':status'}, '200',
        "$path received HTTP/2 status 200");

    if ($path eq '/deferred') {
        is($response->{body}, 'later',
            'deferred streaming response resumed and completed');
        is($response->{header}{'x-spike'}, 'deferred',
            'deferred stream preserved response headers');
    } elsif ($path eq '/body') {
        is($response->{body}, '/body:request-body',
            'POST request body crossed HTTP/2 DATA frames');
        is($response->{header}{'x-spike'}, 'scalar',
            'POST received scalar response');
    } else {
        is($response->{body}, "$path:",
            "$path received its independent response body");
        is($response->{header}{'x-spike'}, 'scalar',
            "$path received scalar response");
    }
}

ok(
    scalar(keys %{$server_state->{request}}) >= 9,
    'server maintained independent state for multiplexed streams',
);

done_testing;

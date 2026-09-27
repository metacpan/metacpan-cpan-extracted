package Linux::Event::HTTP::_HTTP2::Server;
use v5.36;
use strict;
use warnings;

use Scalar::Util qw(blessed refaddr weaken);

use Linux::Event::HTTP::_HTTP2;

our $VERSION = '0.003';

use constant {
    H2_DATA       => 0,
    H2_HEADERS    => 1,
    H2_GOAWAY     => 7,
    H2_END_STREAM => 0x1,
    H2_INTERNAL_ERROR => 2,
    H2_CANCEL     => 8,
    H2_ENHANCE_YOUR_CALM => 11,
};

my $BODY_HIGH_WATER = 65_536;
my $BODY_LOW_WATER  = 32_768;

sub new ($class, %option) {
    my $stream = delete $option{stream};
    die 'new(): stream must be an object with write()'
        if !blessed($stream) || !$stream->can('write');

    my $connection = delete $option{connection};
    my $autostart = exists($option{autostart})
        ? delete($option{autostart}) : 1;
    die 'new(): autostart must be zero or one'
        if !defined($autostart) || ref($autostart)
        || "$autostart" !~ /\A[01]\z/;

    die 'new(): connection must be an object'
        if defined($connection) && !blessed($connection);

    my %callback;
    for my $name (qw(on_request on_body on_request_end on_error)) {
        next if !exists $option{$name};
        my $cb = delete $option{$name};
        die "new(): $name must be a coderef"
            if defined($cb) && ref($cb) ne 'CODE';
        $callback{$name} = $cb if $cb;
    }

    my $max_concurrent_streams =
        delete($option{max_concurrent_streams}) // 100;
    my $max_header_list_size =
        delete($option{max_header_list_size}) // 65_536;
    die 'new(): max_concurrent_streams must be a positive integer'
        if ref($max_concurrent_streams)
        || "$max_concurrent_streams" !~ /\A[0-9]+\z/
        || $max_concurrent_streams < 1;
    die 'new(): max_header_list_size must be a positive integer'
        if ref($max_header_list_size)
        || "$max_header_list_size" !~ /\A[0-9]+\z/
        || $max_header_list_size < 1;

    die 'new(): unknown options: ' . join(', ', sort keys %option)
        if %option;

    require Net::HTTP2::nghttp2;
    Net::HTTP2::nghttp2->VERSION('0.011');
    require Net::HTTP2::nghttp2::Session;
    die 'new(): nghttp2 library is unavailable'
        if !Net::HTTP2::nghttp2->available;

    my $self = bless {
        stream          => $stream,
        connection      => $connection,
        callback        => \%callback,
        session         => undef,
        streams         => {},
        tx_stream       => {},
        current_tx      => undef,
        in_session_call => 0,
        closing         => 0,
        close_pending   => 0,
        transport_blocked => 0,
        transport_ending  => 0,
        closed          => 0,
        started         => 0,
    }, $class;

    my $weak = $self;
    weaken($weak);

    my $session = Net::HTTP2::nghttp2::Session->new_server(
        callbacks => {
            on_begin_headers => sub (@args) {
                my $self = $weak or return 0;
                return 0 if $self->{closing};
                return $self->_on_begin_headers(@args);
            },
            on_header => sub (@args) {
                my $self = $weak or return 0;
                return 0 if $self->{closing};
                return $self->_on_header(@args);
            },
            on_frame_recv => sub (@args) {
                my $self = $weak or return 0;
                return 0 if $self->{closing};
                return $self->_on_frame_recv(@args);
            },
            on_data_chunk_recv => sub (@args) {
                my $self = $weak or return 0;
                return 0 if $self->{closing};
                return $self->_on_data_chunk_recv(@args);
            },
            on_stream_close => sub (@args) {
                my $self = $weak or return 0;
                return 0 if $self->{closing};
                return $self->_on_stream_close(@args);
            },
            on_error => sub (@args) {
                my $self = $weak or return 0;
                return 0 if $self->{closing};
                return $self->_on_session_error(@args);
            },
        },
    );

    $self->{session} = $session;
    $self->{max_concurrent_streams} = 0 + $max_concurrent_streams;
    $self->{max_header_list_size} = 0 + $max_header_list_size;
    $self->start if $autostart;
    return $self;
}

sub start ($self) {
    die 'start(): executor is closed' if $self->{closed};
    return $self if $self->{started};
    $self->{started} = 1;
    $self->{session}->send_connection_preface(
        max_concurrent_streams => $self->{max_concurrent_streams},
        max_header_list_size   => $self->{max_header_list_size},
    );
    $self->flush;
    return $self;
}

sub started ($self) { !!$self->{started} }

sub session ($self) { $self->{session} }
sub stream  ($self) { $self->{stream} }

sub transaction ($self) {
    return $self->{current_tx};
}

sub transaction_for_stream ($self, $stream_id) {
    my $state = $self->{streams}{$stream_id} or return undef;
    return $state->{transaction};
}

sub stream_count ($self) {
    return scalar keys %{$self->{streams}};
}

sub input ($self, $bytes) {
    die 'input(): executor is closed' if $self->{closed};
    die 'input(): executor is not started' if !$self->{started};
    die 'input(): bytes must be a scalar' if ref $bytes;
    return 0 if !defined($bytes) || $bytes eq '';

    my $consumed;
    {
        local $self->{in_session_call} = 1;
        $consumed = $self->{session}->mem_recv($bytes);
    }
    die 'input(): nghttp2 did not consume complete input'
        if !defined($consumed) || $consumed != length($bytes);

    return $consumed if $self->_finish_pending_close;

    $self->flush;
    return $consumed;
}

sub flush ($self) {
    return if $self->{closed} || $self->{closing};
    return if !$self->{started};
    return if $self->{in_session_call};
    return if $self->{transport_blocked};

    {
        local $self->{in_session_call} = 1;
        while ($self->{session}->want_write) {
            my $bytes = $self->{session}->mem_send;
            last if $self->{close_pending};
            last if !defined($bytes) || $bytes eq '';

            my $accepted = $self->{stream}->write($bytes);
            if (!$accepted) {
                $self->{transport_blocked} = 1;
                last;
            }
        }
    }

    return if $self->_finish_pending_close;

    $self->_maybe_end_transport;
    return;
}

sub _maybe_end_transport ($self) {
    return if $self->{closed} || $self->{transport_ending};
    return if $self->{transport_blocked};

    my $session = $self->{session} or return;
    if ($self->{peer_goaway}) {
        return if $self->stream_count;
    } else {
        return if $session->want_read || $session->want_write;
    }

    my $stream = $self->{stream} or return;
    return if $stream->is_closed;

    $self->{transport_ending} = 1;
    $stream->end;
    return;
}

sub transport_drain ($self) {
    return if $self->{closed};
    $self->{transport_blocked} = 0;
    $self->flush;

    for my $state (values %{$self->{streams}}) {
        my $provider = $state->{response_provider} or next;
        next if length($provider->{queue}) >= $BODY_LOW_WATER;
        my $tx = $state->{transaction} or next;
        my $body = $tx->_response_body_object or next;
        $body->_drain;
    }
    return;
}

sub close ($self) {
    return if $self->{closed};

    if ($self->{in_session_call}) {
        $self->{closing} = 1;
        $self->{close_pending} = 1;
        return;
    }

    return $self->_finish_close;
}

sub _finish_pending_close ($self) {
    return 0 if !$self->{close_pending};
    $self->{close_pending} = 0;
    $self->_finish_close;
    return 1;
}

sub _finish_close ($self) {
    return if $self->{closed};
    $self->{closed} = 1;
    $self->{closing} = 0;

    for my $state (values %{$self->{streams}}) {
        my $tx = $state->{transaction} or next;
        next if $tx->is_terminal;
        $tx->_fail('HTTP/2 connection closed');
    }

    $self->{streams} = {};
    $self->{tx_stream} = {};
    $self->{session} = undef;
    return;
}

sub _state ($self, $stream_id) {
    return $self->{streams}{$stream_id} //= {
        header_block => [],
        collecting   => 'initial',
        transaction  => undef,
        response_provider => undef,
        request_end_called => 0,
    };
}

sub _on_begin_headers ($self, $stream_id, $frame_type, $flags) {
    my $state = $self->_state($stream_id);
    $state->{header_limit_exceeded} = 0;
    $state->{header_list_size} = 0;
    if ($state->{transaction}) {
        $state->{trailer_block} = [];
        $state->{collecting} = 'trailer';
    } else {
        $state->{header_block} = [];
        $state->{collecting} = 'initial';
    }
    return 0;
}

sub _on_header ($self, $stream_id, $name, $value, $flags) {
    my $state = $self->_state($stream_id);
    return 0 if $state->{header_limit_exceeded};

    my $size = $state->{header_list_size}
        + length($name) + length($value) + 32;
    if ($size > $self->{max_header_list_size}) {
        $state->{header_limit_exceeded} = 1;
        $self->_stream_failure(
            $stream_id,
            'HTTP/2 request header list exceeds configured limit',
            H2_ENHANCE_YOUR_CALM,
        );
        return 0;
    }
    $state->{header_list_size} = $size;

    my $key = $state->{collecting} eq 'trailer'
        ? 'trailer_block'
        : 'header_block';
    $state->{$key} //= [];
    push @{$state->{$key}}, [ $name, $value ];
    return 0;
}

sub _on_frame_recv ($self, $frame) {
    if (($frame->{type} // -1) == H2_GOAWAY) {
        # GOAWAY is a peer drain signal, not a reason to abort the transport.
        # Keep reading until the peer closes so unread TLS/TCP bytes cannot
        # turn an otherwise graceful shutdown into an RST.
        $self->{peer_goaway} = 1;
        return 0;
    }

    my $stream_id = $frame->{stream_id} // 0;
    return 0 if !$stream_id;

    if (($frame->{type} // -1) == H2_HEADERS) {
        my $state = $self->_state($stream_id);
        return 0 if $state->{header_limit_exceeded};

        if (!$state->{transaction}) {
            my $ok = eval {
                my $tx = Linux::Event::HTTP::_HTTP2
                    ->server_transaction_from_headers(
                        $state->{header_block},
                        $self,
                        end_stream => (($frame->{flags} // 0) & H2_END_STREAM)
                            ? 1 : 0,
                    );

                $state->{transaction} = $tx;
                $self->{tx_stream}{refaddr($tx)} = $stream_id;
                $self->_invoke('on_request', $stream_id, $tx);
                $self->_maybe_auto_send($tx);

                if (($frame->{flags} // 0) & H2_END_STREAM) {
                    $self->_request_end($stream_id, $tx);
                }
                1;
            };
            if (!$ok) {
                $self->_stream_failure($stream_id, "$@");
            }
            return 0;
        }

        # Request trailers are valid HTTP/2 but the public message API does not
        # yet expose trailers. Preserve stream completion without folding them
        # into the initial lossless field list.
        if (($frame->{flags} // 0) & H2_END_STREAM) {
            $self->_request_end($stream_id, $state->{transaction});
        }
        return 0;
    }

    if (($frame->{type} // -1) == H2_DATA
        && (($frame->{flags} // 0) & H2_END_STREAM)) {
        my $state = $self->{streams}{$stream_id};
        if ($state && $state->{transaction}) {
            $self->_request_end($stream_id, $state->{transaction});
        }
    }

    return 0;
}

sub _on_data_chunk_recv ($self, $stream_id, $data, $flags) {
    my $state = $self->{streams}{$stream_id};
    return 0 if !$state || !$state->{transaction};

    my $tx = $state->{transaction};
    my $cb = $self->{callback}{on_body};
    if ($cb) {
        my $ok = $self->_invoke('on_body', $stream_id, $tx, $data);
        return 0 if !$ok;
    }

    $self->_maybe_auto_send($tx);
    return 0;
}

sub _request_end ($self, $stream_id, $tx) {
    my $state = $self->{streams}{$stream_id} or return;
    return if $state->{request_end_called}++;

    $tx->request->_mark_complete if !$tx->request->is_complete;
    $self->_invoke('on_request_end', $stream_id, $tx)
        if $self->{callback}{on_request_end};
    $self->_maybe_auto_send($tx);
    return;
}

sub _invoke ($self, $name, $stream_id, $tx, @extra) {
    my $cb = $self->{callback}{$name} or return 1;
    my $connection = $self->{connection} // $self;
    my $ok = eval {
        local $self->{current_tx} = $tx;
        if ($name eq 'on_body') {
            $cb->($connection, $tx->request, $tx->response, $extra[0]);
        } else {
            $cb->($connection, $tx->request, $tx->response);
        }
        1;
    };
    if (!$ok) {
        $self->_stream_failure($stream_id, "$@");
        return 0;
    }
    return 1;
}

sub _stream_failure (
    $self, $stream_id, $error, $code = H2_INTERNAL_ERROR,
) {
    $error = 'HTTP/2 stream failure' if !defined($error) || $error eq '';

    my $state = $self->{streams}{$stream_id};
    if ($state && (my $tx = $state->{transaction})) {
        $tx->_fail($error) if !$tx->is_terminal;
    }

    eval { $self->{session}->submit_rst_stream($stream_id, $code) };

    if (my $cb = $self->{callback}{on_error}) {
        eval { $cb->($self, $stream_id, $error) };
    }
    return;
}

sub _on_session_error ($self, $lib_error_code, $message) {
    if (my $cb = $self->{callback}{on_error}) {
        eval { $cb->($self, 0, "$message") };
    }
    return 0;
}

sub _on_stream_close ($self, $stream_id, $error_code) {
    my $state = delete $self->{streams}{$stream_id};
    return 0 if !$state;

    my $tx = $state->{transaction};
    return 0 if !$tx;

    delete $self->{tx_stream}{refaddr($tx)};

    if (!$tx->is_terminal) {
        if ($error_code) {
            $tx->_fail("HTTP/2 stream closed with error $error_code");
        } else {
            $tx->_mark_complete;
        }
    }

    return 0;
}

sub _stream_id_for_tx ($self, $tx, $operation) {
    my $stream_id = $self->{tx_stream}{refaddr($tx)};
    die "$operation: Transaction is not active on this HTTP/2 connection"
        if !defined $stream_id;
    return $stream_id;
}

sub _normal_response_headers ($self, $response) {
    my $block = Linux::Event::HTTP::_HTTP2->response_headers($response);
    return [ @$block[1 .. $#$block] ];
}

sub _maybe_auto_send ($self, $tx) {
    return if $tx->is_terminal || $tx->is_response_started;
    my $response = $tx->response or return;
    return if !$response->_has_scalar_body;
    $self->_send_http_response($tx);
    return;
}

sub _send_http_response ($self, $tx) {
    my $stream_id = $self->_stream_id_for_tx(
        $tx, '_send_http_response()',
    );
    die '_send_http_response(): response output already started'
        if $tx->is_response_started;

    my $response = $tx->response
        or die '_send_http_response(): Transaction has no Response';
    my $body = $response->_scalar_body;
    die '_send_http_response(): Response has no complete scalar body'
        if !defined $body;

    my $headers = $self->_normal_response_headers($response);
    $response->_commit;
    $self->{session}->submit_response(
        $stream_id,
        status  => $response->status,
        headers => $headers,
        body    => $body,
    );

    $tx->_mark_response_started;
    $tx->_mark_response_output_complete;
    $self->flush;
    return 1;
}

sub _response_data_provider ($stream_id, $max_length, $provider) {
    my $queue = $provider->{queue};

    if (!length($queue)) {
        return ('', 1) if $provider->{eof};
        return;
    }

    my $take = length($queue) < $max_length
        ? length($queue)
        : $max_length;
    my $chunk = substr($provider->{queue}, 0, $take, '');
    my $eof = $provider->{eof} && !length($provider->{queue}) ? 1 : 0;

    if ($provider->{blocked}
        && length($provider->{queue}) < $BODY_LOW_WATER) {
        $provider->{blocked} = 0;
        if (my $tx = $provider->{transaction}) {
            if (my $body = $tx->_response_body_object) {
                $body->_drain;
            }
        }
    }

    return ($chunk, $eof);
}

sub _start_response_provider ($self, $tx, $stream_id) {
    my $response = $tx->response
        or die 'response_body: Transaction has no Response';

    my $provider = {
        queue       => '',
        eof         => 0,
        blocked     => 0,
        transaction => $tx,
    };
    weaken($provider->{transaction});

    my $headers = $self->_normal_response_headers($response);
    $response->_commit;
    $self->{session}->submit_response(
        $stream_id,
        status        => $response->status,
        headers       => $headers,
        data_callback => \&_response_data_provider,
        callback_data => $provider,
    );

    my $state = $self->{streams}{$stream_id}
        or die 'response_body: HTTP/2 stream state disappeared';
    $state->{response_provider} = $provider;
    $tx->_mark_response_started;
    return $provider;
}

sub _write_http_response_body ($self, $tx, $bytes, $final, $operation) {
    my $stream_id = $self->_stream_id_for_tx($tx, "$operation()");
    die "$operation(): body must be a scalar" if ref $bytes;
    $bytes = '' if !defined $bytes;

    my $state = $self->{streams}{$stream_id}
        or die "$operation(): HTTP/2 stream state disappeared";
    my $provider = $state->{response_provider}
        // $self->_start_response_provider($tx, $stream_id);

    $provider->{queue} .= $bytes;
    $provider->{eof} = 1 if $final;

    if ($self->{session}->is_stream_deferred($stream_id)) {
        $self->{session}->resume_stream($stream_id);
    }

    if ($final) {
        $tx->_mark_response_output_complete;
    }

    my $blocked = $self->{transport_blocked}
        || length($provider->{queue}) >= $BODY_HIGH_WATER;
    $provider->{blocked} = 1 if $blocked;

    $self->flush;
    return $blocked ? 0 : 1;
}

sub _write_http_request_body ($self, $tx, $bytes, $final, $operation) {
    die "$operation(): server HTTP/2 executor cannot write a Request body";
}

sub _cancel_http_transaction ($self, $tx) {
    my $stream_id = $self->{tx_stream}{refaddr($tx)};
    return if !defined $stream_id;

    $self->{session}->submit_rst_stream($stream_id, H2_CANCEL);
    $tx->_mark_cancelled if !$tx->is_terminal;
    $self->flush;
    return;
}

sub _upgrade_http_transaction ($self, $tx, $target_class) {
    die 'upgrade(): HTTP/1 whole-transport Upgrade is not available on HTTP/2';
}

sub _tunnel_http_transaction ($self, $tx, $target_class) {
    die 'tunnel(): HTTP/2 CONNECT requires a stream-level tunnel abstraction';
}

1;

__END__

=head1 NAME

Linux::Event::HTTP::_HTTP2::Server - private HTTP/2 server executor

=head1 DESCRIPTION

This private executor owns one nghttp2 server Session and maps each HTTP/2
stream to one Linux::Event::HTTP::Transaction.

It is an integration layer for development of HTTP/2 support. It is not a
public server connection class.

=cut

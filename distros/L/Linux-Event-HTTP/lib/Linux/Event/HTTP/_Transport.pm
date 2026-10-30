package Linux::Event::HTTP::_Transport;
use v5.36;
use parent 'Linux::Event::IO::Sock::Stream';
use Scalar::Util qw(weaken blessed);
use Carp qw(croak);

sub on_ready ($self) {
    my $state = $self->data;
    if (my $ready = delete $state->{ready}) {
        my $engine = $ready->(
            transport => $self, alpn => $self->selected_alpn,
            verified_origin => $state->{verified_origin} ? 1 : 0,
        );
        if ($self->is_closed) {
            $engine->transport_error('HTTP transport closed during attachment') if $engine;
            return;
        }
        $self->{http_engine} = $engine;
        $self->{http_multiplexed} = $engine && $engine->isa('Unblock::HTTP2::_Connection');
        $self->close unless $engine;
    } elsif (my $server = $state->{server}) {
        my $engine = $server->_attach($self);
        if ($self->is_closed) {
            $engine->transport_error('HTTP transport closed during attachment') if $engine;
            return;
        }
        $self->{http_engine} = $engine;
        $self->{http_multiplexed} = $engine && $engine->isa('Unblock::HTTP2::_Connection');
        $self->close unless $engine;
    } else {
        $self->close;
    }
    return;
}

sub on_eof ($self) {
    my $engine = $self->{http_engine};
    $engine->input_eof if $engine && $engine->want_read;
    return;
}

sub on_drain ($self) {
    $self->{http_output_blocked} = 0;
    $self->_http_flush;
    return;
}

sub _http_flush ($self) {
    return if $self->is_closed || $self->{http_output_blocked};
    my $engine = $self->{http_engine};
    $engine->resume_output if $engine;
    $self->_http_maybe_finish if $self->{http_multiplexed};
    return;
}

sub _http_maybe_finish ($self) {
    return unless $self->{http_multiplexed};
    return if $self->is_closed || $self->{http_output_blocked} || $self->{http_finish_scheduled};
    my $engine = $self->{http_engine} or return;
    return if $engine->want_read || $engine->want_write;
    # nghttp2 has no further input or output after its final GOAWAY/stream.
    # End outside protocol callbacks, preserving bytes already in our queue.
    $self->{http_finish_scheduled} = 1;
    my $weak = $self;
    weaken($weak);
    $self->loop->defer(sub {
        my $stream = $weak or return;
        delete $stream->{http_finish_scheduled};
        return if $stream->is_closed || $stream->{http_output_blocked};
        my $engine = $stream->{http_engine} or return;
        $stream->end unless $engine->want_read || $engine->want_write;
    });
    return;
}

sub _http_drain ($self) {
    if (my $engine = $self->{http_engine}) {
        $engine->drain;
    } else {
        # No admitted HTTP request exists during a TLS handshake.
        $self->close;
    }
    return;
}

sub on_error ($self, $error) {
    if (my $ready = delete $self->data->{ready}) {
        $ready->(error => "$error");
    }
    my $engine = $self->{http_engine};
    $engine->transport_error("$error") if $engine;
    return;
}

sub _http_input_failed ($self, $error) {
    my $engine = $self->{http_engine};
    $engine->transport_error($error) if $engine;
    $self->close unless $self->is_closed;
    return;
}

sub on_close ($self) {
    # Remove before notifying: transport_error may call unblock_abort again.
    my $engine = delete $self->{http_engine};
    my $state = $self->data;
    $engine->transport_error('HTTP transport closed') if $engine;
    if (my $server = $state->{server}) {
        $server->_closed($self);
    }
    if (my $ready = delete $state->{ready}) {
        $ready->(error => 'HTTP transport closed before readiness');
    }
    return;
}

# Unblock::HTTP owns the HTTP1 handshake and the successor protocol.
# This is a socket-wide (never H2/H3 stream-local) transition. Linux::Event
# retains the write queue and, for native input, the unread borrowed tail.
sub unblock_upgrade ($self, $successor) {
    croak 'unblock_upgrade(): requires an established protocol consumer'
        unless blessed($successor)
            && $successor->can('input') && $successor->can('input_eof')
            && $successor->can('transport_error')
            && $successor->can('resume_output');
    croak 'unblock_upgrade(): socket already upgraded'
        if $self->{http_successor};
    croak 'unblock_upgrade(): multiplexed HTTP cannot transfer the socket'
        if $self->{http_multiplexed};
    croak 'unblock_upgrade(): no HTTP engine is attached'
        unless $self->{http_engine};
    require Linux::Event::HTTP::_UpgradedStream;
    $self->{http_successor} = $successor;
    my $ok = eval {
        $self->transition_to('Linux::Event::HTTP::_UpgradedStream');
        1;
    };
    unless ($ok) {
        delete $self->{http_successor};
        die $@;
    }
    delete $self->{http_engine};
    delete $self->{http_multiplexed};
    return;
}

sub unblock_send ($self, $bytes) {
    my $ready = $self->write($bytes);
    die "HTTP transport closed during output\n" if $self->is_closed;
    $self->{http_output_blocked} = !$ready;
    $self->_http_maybe_finish if $self->{http_multiplexed};
    return $ready;
}

sub unblock_finish ($self) { $self->end }
sub unblock_abort ($self, $reason) { $self->close }

1;

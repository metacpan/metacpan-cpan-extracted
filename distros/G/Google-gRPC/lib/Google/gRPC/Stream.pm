package Google::gRPC::Stream;

use strict;
use warnings;
use Moo;
use Time::HiRes qw(time);
use Google::gRPC::Framing;
use Carp qw(croak);

has stream_id      => ( is => 'ro', required => 1 );
has channel        => ( is => 'ro', required => 1 );
has type           => ( is => 'ro', default => sub { 'unary' } );
has response_class => ( is => 'ro', required => 0 );
has on_message     => ( is => 'rw' );
has on_trailers    => ( is => 'rw' );
has on_close       => ( is => 'rw' );
has pool           => ( is => 'rw' );
has ip_key         => ( is => 'rw' );
has deadline       => ( is => 'rw' );

has state            => ( is => 'rw', default => sub { 'open' } );
has read_buffer      => ( is => 'rw', default => sub { '' } );
has response_queue   => ( is => 'rw', default => sub { [] } );
has status           => ( is => 'rw', default => sub { 0 } );
has status_message   => ( is => 'rw', default => sub { '' } );
has status_details   => ( is => 'rw' );
has headers_received => ( is => 'rw', default => sub { 0 } );

sub write_message {
    my ($self, $msg, $end_stream) = @_;
    $self->check_deadline();
    return if $self->state eq 'closed';

    my $binary_payload;
    if (ref($msg) && $msg->can('serialize')) {
        $binary_payload = $msg->serialize();
    }
    elsif (defined $msg) {
        $binary_payload = $msg;
    }
    else {
        $binary_payload = '';
    }

    my $framed = Google::gRPC::Framing::pack_frame($binary_payload);
    if ($self->pool && $self->ip_key) {
        $self->pool->record_request($self->ip_key, length($framed));
    }
    $self->channel->send_stream_data($self->stream_id, $framed, $end_stream);

    if ($end_stream) {
        if ($self->state eq 'half_closed_remote') {
            $self->state('closed');
        }
        else {
            $self->state('half_closed_local');
        }
    }
}

sub close_write {
    my ($self) = @_;
    $self->write_message(undef, 1);
}

sub push_incoming_data {
    my ($self, $chunk) = @_;
    $self->check_deadline();
    return if $self->state eq 'closed';
    return unless defined $chunk && length($chunk);

    my $buf = $self->read_buffer . $chunk;
    my @frames = Google::gRPC::Framing::unpack_frame(\$buf);
    $self->read_buffer($buf);

    for my $frame (@frames) {
        my $payload = $frame->{payload};
        my $parsed_msg = $payload;

        if ($self->response_class && $self->response_class->can('parse')) {
            $parsed_msg = $self->response_class->parse($payload);
        }

        push @{$self->response_queue}, $parsed_msg;

        if (my $cb = $self->on_message) {
            $cb->($self, $parsed_msg);
        }
    }
}

sub recv_message {
    my ($self) = @_;
    $self->check_deadline();
    return shift @{$self->response_queue};
}

sub handle_trailers {
    my ($self, $trailers) = @_;
    return if $self->state eq 'closed';

    my $info = Google::gRPC::Framing::parse_trailers($trailers);
    $self->status($info->{status});
    $self->status_message($info->{message});
    if ($info->{status_details}) {
        $self->status_details($info->{status_details});
    }

    if (my $cb = $self->on_trailers) {
        $cb->($self, $info);
    }
}

sub handle_close {
    my ($self, $code) = @_;
    return if $self->state eq 'closed';
    $self->state('closed');
    if (my $cb = $self->on_close) {
        $cb->($self, $self->status, $self->status_message);
    }
}

sub check_deadline {
    my ($self) = @_;
    return unless defined $self->deadline;
    return if $self->state eq 'closed';

    if (time() > $self->deadline) {
        $self->abort_stream(4, 'Deadline Exceeded');
    }
}

sub abort_stream {
    my ($self, $status_code, $status_msg) = @_;
    $status_code //= 4;
    $status_msg //= 'Deadline Exceeded';

    $self->status($status_code);
    $self->status_message($status_msg);

    my $info = {
        status  => $status_code,
        message => $status_msg,
    };

    if (my $cb = $self->on_trailers) {
        $cb->($self, $info);
    }
    $self->handle_close($status_code);
}


=head1 NAME

Google::gRPC::Stream - Active HTTP/2 gRPC RPC stream state machine

=head1 SYNOPSIS

    use Google::gRPC::Stream;

    # Typically created via Google::gRPC::Channel->create_stream(...)
    my $stream = $channel->create_stream(
        method         => '/google.pubsub.v1.Publisher/Publish',
        response_class => 'Google::Pubsub::V1::PublishResponse',
        deadline       => time() + 30,
        on_message     => sub {
            my ($stream, $msg) = @_;
            ...
        },
        on_trailers    => sub {
            my ($stream, $info) = @_;
            warn "Status: $info->{status} ($info->{message})\n";
        },
        on_close       => sub {
            my ($stream, $status, $message) = @_;
            ...
        },
    );

    # Send a message (pass 1 as second arg to half-close the send side)
    $stream->write_message($req_msg, 1);

    # Or pull buffered responses synchronously
    while (my $msg = $stream->recv_message()) {
        ...
    }

=head1 DESCRIPTION

C<Google::gRPC::Stream> represents a single active gRPC RPC stream multiplexed
over an HTTP/2 connection managed by L<Google::gRPC::Channel>. It handles
length-prefixed gRPC message framing via L<Google::gRPC::Framing>, optional
automatic Protobuf deserialization into C<response_class>, deadline
enforcement, and lifecycle callbacks (C<on_message>, C<on_trailers>,
C<on_close>).

=head1 ATTRIBUTES

=over 4

=item C<stream_id> (required, read-only)

HTTP/2 stream identifier assigned by the underlying transport engine.

=item C<channel> (required, read-only)

Parent L<Google::gRPC::Channel> instance.

=item C<type> (read-only, default C<'unary'>)

RPC streaming mode (e.g. C<unary>, C<client_streaming>, C<server_streaming>,
C<bidi_streaming>).

=item C<response_class> (optional, read-only)

Protobuf Perl class name (supporting C<parse($bytes)>) used to deserialize
incoming message payloads automatically.

=item C<on_message> / C<on_trailers> / C<on_close> (read-write)

Optional coderef callbacks invoked as messages arrive, trailers are parsed,
or the stream closes.

=item C<deadline> (read-write)

Optional absolute epoch timestamp (from L<Time::HiRes/time>). When exceeded,
L</check_deadline> aborts the stream with status C<4> (C<DEADLINE_EXCEEDED>).

=item C<state> (read-write, default C<'open'>)

Current stream state: C<open>, C<half_closed_local>, C<half_closed_remote>,
or C<closed>.

=item C<status> / C<status_message> / C<status_details> (read-write)

Final gRPC status code (default C<0>), status message, and optional decoded
C<grpc-status-details-bin> payload.

=item C<pool> / C<ip_key> (read-write)

Optional L<Google::gRPC::ChannelPool> reference and endpoint IP key for byte
accounting.

=back

=head1 METHODS

=head2 write_message($msg, $end_stream)

    $stream->write_message($protobuf_msg, 0);
    $stream->write_message($protobuf_msg, 1); # half-close write side

Serializes C<$msg> (calling C<< $msg->serialize() >> if it is an object),
wraps it in a 5-byte gRPC frame, records pool metrics if attached, and sends
it via the parent channel. If C<$end_stream> is true, transitions C<state> to
C<half_closed_local> (or C<closed> if already C<half_closed_remote>).

=head2 close_write()

    $stream->close_write();

Convenience wrapper for C<< $stream->write_message(undef, 1) >> to signal
end-of-stream on the client send side.

=head2 push_incoming_data($chunk)

    $stream->push_incoming_data($bytes);

Appends raw HTTP/2 DATA bytes to C<read_buffer>, unpacks any complete gRPC
frames, deserializes them via C<response_class> when configured, enqueues them
into C<response_queue>, and invokes C<on_message>.

=head2 recv_message()

    my $msg = $stream->recv_message();

Checks the stream deadline and shifts the next buffered response message off
C<response_queue>, or returns C<undef> if none is available.

=head2 handle_trailers($trailers)

    $stream->handle_trailers(\%trailers);

Parses gRPC trailing headers via L<Google::gRPC::Framing/parse_trailers>,
populates C<status>, C<status_message>, and C<status_details>, and invokes
C<on_trailers>.

=head2 handle_close($code)

    $stream->handle_close($code);

Transitions the stream to C<closed> and invokes C<on_close>.

=head2 check_deadline()

    $stream->check_deadline();

Checks whether C<time() E<gt> $self-E<gt>deadline> and, if so, calls
L</abort_stream> with status C<4> (C<Deadline Exceeded>).

=head2 abort_stream($status_code, $status_msg)

    $stream->abort_stream(4, 'Deadline Exceeded');

Terminates the stream with the given gRPC status code and message, firing
C<on_trailers> and L</handle_close>.

=head1 SEE ALSO

L<Google::gRPC>, L<Google::gRPC::Channel>, L<Google::gRPC::ChannelPool>,
L<Google::gRPC::Framing>, L<Google::gRPC::Deadline>

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;

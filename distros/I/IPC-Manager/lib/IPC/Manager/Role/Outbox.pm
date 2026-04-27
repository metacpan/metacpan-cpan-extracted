package IPC::Manager::Role::Outbox;
use strict;
use warnings;

our $VERSION = '0.000035';

use Carp qw/croak/;

use Role::Tiny;

requires qw{
    _outbox_try_write
    _outbox_writable_handle
    _outbox_set_blocking
    _outbox_can_send
};

# Per-spec: queued messages may flush in any order. The role does not
# preserve order across queued messages or between a queued message
# and a directly-written message. Callers that need strict ordering
# must keep the client in send_blocking=1 (the default).

sub try_send_message {
    my $self = shift;

    # Match send_message's call signature: caller may pass a Message
    # object, ($peer, \%content) pair, or full %args. build_message
    # + serializer produce the wire payload exactly the same way the
    # blocking path does.
    my ($peer, $payload);
    if (@_ >= 2 && ref($_[1]) eq '' && !ref($_[0])) {
        # Pre-serialized fast path: ($peer, $payload_string).
        ($peer, $payload) = @_;
    }
    else {
        my $msg = $self->build_message(@_);
        $peer    = $msg->to or croak "No peer specified";
        $payload = $self->serializer->serialize($msg);
    }

    return 1 if $self->_outbox_try_write($peer, $payload);

    push @{$self->{_OUTBOX}{$peer}} => [$payload];
    return 0;
}

sub drain_pending {
    my $self = shift;

    my $delivered = 0;
    for my $peer (keys %{$self->{_OUTBOX} // {}}) {
        my $q = $self->{_OUTBOX}{$peer} or next;
        while (@$q) {
            my ($payload, $fields) = @{$q->[0]};
            last unless $self->_outbox_try_write($peer, $payload, %$fields);
            shift @$q;
            $delivered++;
        }
        delete $self->{_OUTBOX}{$peer} unless @$q;
    }

    return $delivered;
}

sub pending_sends {
    my $self = shift;

    my $n = 0;
    $n += scalar @$_ for values %{$self->{_OUTBOX} // {}};
    return $n;
}

# Boolean fast path: prefer this over pending_sends() when callers only
# need "is there anything queued?" so we can short-circuit on the first
# non-empty queue instead of summing every peer's backlog.
sub have_pending_sends {
    my $self = shift;
    for my $q (values %{$self->{_OUTBOX} // {}}) {
        return 1 if @$q;
    }
    return 0;
}

sub pending_sends_to {
    my $self = shift;
    my ($peer) = @_;
    return scalar @{$self->{_OUTBOX}{$peer} // []};
}

sub have_writable_handles {
    my $self = shift;
    return 0 unless keys %{$self->{_OUTBOX} // {}};

    for my $peer (keys %{$self->{_OUTBOX}}) {
        next unless @{$self->{_OUTBOX}{$peer}};
        return 1 if defined $self->_outbox_writable_handle($peer);
    }

    return 0;
}

sub writable_handles {
    my $self = shift;
    my @h;
    for my $peer (keys %{$self->{_OUTBOX} // {}}) {
        next unless @{$self->{_OUTBOX}{$peer}};
        my $h = $self->_outbox_writable_handle($peer);
        push @h => $h if defined $h;
    }
    return @h;
}

sub send_blocking {
    my $self = shift;
    return $self->{_SEND_BLOCKING} // 1;
}

sub set_send_blocking {
    my ($self, $bool) = @_;
    my $val = $bool ? 1 : 0;
    return if defined $self->{_SEND_BLOCKING} && $self->{_SEND_BLOCKING} == $val;
    $self->{_SEND_BLOCKING} = $val;
    $self->_outbox_set_blocking($val);
    return;
}

sub can_send_to {
    my ($self, $peer) = @_;
    return 0 if $self->pending_sends_to($peer);
    return $self->_outbox_can_send($peer) ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Role::Outbox - Non-blocking outbound queue for clients

=head1 DESCRIPTION

A client that consumes this role can never block on a full transport
buffer when running in non-blocking mode (C<send_blocking=0>). Calls
that would otherwise block are deferred to a per-peer outbox; the
service event loop drains the outbox via C<drain_pending> when the
writable handles for the affected peers become writable again.

The role is intended for clients whose transport can return EAGAIN
mid-write (FIFO-based, datagram-socket-based). Memory- or DB-backed
clients do not need this role; the base class
L<IPC::Manager::Client> provides no-op fallbacks so service code can
call the API uniformly.

=head1 BLOCKING MODE

The blocking flag is per-client and toggleable.

=over 4

=item Default: C<send_blocking=1>

Calls to C<send_message> block until bytes are committed. Suitable for
short-lived caller code where backpressure-induced waits are
preferable to lost messages.

=item Inside a service: C<send_blocking=0>

Set by C<IPC::Manager::Role::Service> at startup. C<send_message>
delegates to C<try_send_message>; queued messages flush from the
service's event loop when the transport reports writability.

=back

=head1 ORDERING (IMPORTANT)

Queued messages are NOT delivered in their enqueue order with respect
to one another or to subsequently-sent direct writes. The role drains
peers in arbitrary hash order. Callers that depend on strict ordering
must keep the client in blocking mode.

=head1 REQUIRED METHODS

Consumers must implement:

=over 4

=item $bool = $self->_outbox_try_write($peer, $payload, %fields)

Attempt a non-blocking write. Returns true on full delivery, false
when the transport returned EAGAIN (or when an Atomic::Pipe still
has bytes pending in its OUT_BUFFER after a non-blocking flush).

=item $fh = $self->_outbox_writable_handle($peer)

Return a filehandle that becomes writable when the kernel has room
again for C<$peer>. May return C<undef> if no such handle exists.

=item $self->_outbox_set_blocking($bool)

Apply the new blocking mode to all underlying transports.

=item $bool = $self->_outbox_can_send($peer)

Return true if a non-blocking write to C<$peer> would succeed
immediately.

=back

=head1 PROVIDED METHODS

C<try_send_message>, C<drain_pending>, C<pending_sends>,
C<have_pending_sends>, C<pending_sends_to>, C<have_writable_handles>,
C<writable_handles>, C<send_blocking>, C<set_send_blocking>,
C<can_send_to>.

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut

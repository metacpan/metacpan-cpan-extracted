package IPC::Manager::Service::Handle;
use strict;
use warnings;

our $VERSION = '0.000030';

use Carp qw/croak/;
use Time::HiRes qw/time/;
use Test2::Util::UUID qw/gen_uuid/;

use IPC::Manager::Util qw/tinysleep/;

use Role::Tiny::With;

with 'IPC::Manager::Role::Service::Select';
with 'IPC::Manager::Role::Service::Requests';

use Object::HashBase qw{
    <service_name
    <name
    <ipcm_info

    interval

    <child_pid

    +client

    +request_callbacks
    +requests

    +buffer

    +spawn
};

sub _set_child_pid { $_[0]->{+CHILD_PID} = $_[1] }

sub init {
    my $self = shift;

    $self->clear_servicerequests_fields;
    $self->clear_serviceselect_fields;

    croak "'service_name' is a required attribute" unless $self->{+SERVICE_NAME};
    croak "'ipcm_info' is a required attribute" unless $self->{+IPCM_INFO};

    $self->{+INTERVAL} //= 0.2;

    $self->{+NAME} //= gen_uuid();
}

sub DESTROY {
    my $self = shift;

    # Disconnect the client before the spawn is destroyed, otherwise the
    # spawn's unspawn() may remove shared resources (e.g. SysV semaphores)
    # that the client's disconnect/write_stats still needs.
    if (my $client = delete $self->{+CLIENT}) {
        local $@;
        eval { $client->disconnect; 1 } or warn $@;
    }
}

sub select_handles {
    my $self   = shift;
    my $client = $self->client;
    return $client->have_handles_for_select ? $client->handles_for_select : ();
}

sub ready {
    my $self = shift;
    my ($timeout) = @_;
    $self->client->peer_active($self->{+SERVICE_NAME}, $timeout);
}

sub client {
    my $self = shift;
    return $self->{+CLIENT} if $self->{+CLIENT};

    require IPC::Manager;
    return $self->{+CLIENT} = IPC::Manager->connect($self->{+NAME}, $self->{+IPCM_INFO});
}

sub service_pid {
    my $self = shift;
    $self->client->peer_pid($self->service_name);
}

sub sync_request {
    my $self = shift;
    my ($peer, $payload, $timeout) = @_;
    my $id = $self->send_request($peer, $payload);
    return $self->await_response($id, $timeout);
}

sub await_response {
    my $self = shift;
    my ($id, $timeout) = @_;

    my $client   = $self->client;
    my $interval = $self->{+INTERVAL};
    my $deadline = defined($timeout) ? time + $timeout : undef;

    while (1) {
        my @out = $self->get_response($id);
        return $out[0] if @out;

        my ($peer, $pid) = $self->pending_response_peer($id);
        if ($peer) {
            # Protocols that advertise suspend_supported let peers suspend
            # cleanly (pidfile dropped) or restart under a new pid while the
            # registration stays in place.  A missing pid or a pid mismatch
            # is therefore not a failure on its own — only full
            # unregistration is.  Protocols without suspend treat a dead or
            # missing pid as a permanent loss.
            my $active;
            if ($client->suspend_supported) {
                $active = $client->peer_exists($peer) ? 1 : 0;
            }
            elsif (defined $pid) {
                $active = $client->pid_is_running($pid) ? 1 : 0;
            }
            else {
                $active = $client->peer_active($peer);
            }

            croak "peer '$peer' went away while awaiting response '$id'"
                unless $active;
        }

        my $wait = $interval;
        if (defined $deadline) {
            my $remaining = $deadline - time;
            croak "await_response: timed out after ${timeout}s waiting for response '$id'"
                if $remaining <= 0;

            $wait = $remaining if $remaining < $wait;
        }

        $self->poll($wait);
    }
}

sub await_all_responses {
    my $self = shift;

    $self->poll while $self->have_pending_responses;

    return;
}

sub messages {
    my $self = shift;
    my $messages = delete $self->{+BUFFER};
    return unless $messages;
    return @$messages;
}

sub poll {
    my $self = shift;
    my ($timeout) = @_;

    my $client = $self->client;

    my @messages;
    if (my $select = $self->select) {
        if ($select->can_read($timeout)) {
            @messages = $client->get_messages;
        }
    }
    else {
        my $start = $timeout ? time : 0;

        while (1) {
            @messages = $client->get_messages;
            last if @messages;

            if (defined $timeout) {
                last unless $timeout; # timeout is 0

                my $delta = time - $start;
                last if $delta >= $timeout
            }

            tinysleep($self->{+INTERVAL});
        }
    }

    return unless @messages;

    # handle the messages
    # Split into regular message to go in the buffer and handle responses
    for my $msg (@messages) {
        my $c = $msg->content;

        if (ref($c) eq 'HASH' && $c->{ipcm_response_id}) {
            $self->handle_response($c, $msg);
        }
        else {
            push @{$self->{+BUFFER}} => $msg;
        }
    }

    return scalar @messages;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Service::Handle - Handle class for connecting to IPC services

=head1 DESCRIPTION

This class provides a client-side handle for connecting to IPC services.
It manages the connection to a service and provides methods for sending
requests and receiving responses.

It composes with L<IPC::Manager::Role::Service::Select> and
L<IPC::Manager::Role::Service::Requests> for I/O multiplexing and
request/response patterns.

=head1 SYNOPSIS

    my $handle = IPC::Manager::Service::Handle->new(
        service_name => 'my-service',
        ipcm_info    => $ipcm_info,
    );

    # Send a synchronous request
    my $response = $handle->sync_request({action => 'do_something'});

    # Poll for messages
    $handle->poll;

    # Get buffered messages
    my @messages = $handle->messages;

=head1 ATTRIBUTES

=over 4

=item service_name

The name of the service to connect to (required).

=item name

The name of this handle connection (optional, defaults to a UUID).

=item ipcm_info

Connection information for the IPC system (required).

=item interval

Polling interval in seconds (default: 0.2).

=item client

The underlying client connection (internal use).

=item request_callbacks

Hash of request callbacks (internal use).

=item requests

Hash of pending requests (internal use).

=item buffer

Array of received messages (internal use).

=back

=head1 METHODS

=over 4

=item @file_handles = $self->select_handles()

Returns a list of filehandles for select().

=item $bool = $self->ready()

=item $bool = $self->ready($timeout)

Returns true if the handle's peer service is active.

With no argument (or C<undef>), C<ready> returns the current state
immediately (one-shot, backwards-compatible).

With C<$timeout>, C<ready> blocks until the peer becomes active or the
timeout elapses, whichever comes first.  A C<$timeout> of C<0> blocks
indefinitely.

Uses the underlying client's peer-change notification handle
(C<IO::Select> on an inotify/similar fd) where available; otherwise
falls back to a short sub-second sleep-and-retry loop.

=item $client = $self->client()

Returns the client connection, creating it if necessary.

=item $pid = $self->service_pid()

Returns the PID of the peer service.

=item $pid = $self->child_pid()

Returns the pid that C<fork> returned in C<ipcm_service>'s parent branch
(the "first-fork" pid).  Populated only when the handle was produced by
C<ipcm_service> spawning a child; C<undef> otherwise (e.g. on handles
constructed directly via C<< IPC::Manager->connect >>).

B<Caveat>: this is C<ipcm_service>'s own fork pid, not necessarily the pid
the service loop ends up running in.  If a C<post_fork_hook> daemonizes
(double-fork + parent-exit), the first-fork pid exits inside the hook and
this value becomes stale; use C<service_pid> to retrieve the currently
running service pid in that case.  If a C<post_fork_hook> interposes a
long-lived wrapper (parent becomes the wrapper, child runs the service
loop), C<child_pid> is the wrapper pid and is the correct pid for a
supervisor to watch.

=item $res = $self->sync_request($peer, $payload)

=item $res = $self->sync_request($peer, $payload, $timeout)

Sends a request and waits for the response. Returns the response.

If C<$timeout> (seconds) is provided, C<sync_request> will C<croak> with a
timeout message if no response arrives before the deadline. If C<$timeout>
is omitted or C<undef>, the call blocks indefinitely.

Regardless of the timeout, C<sync_request> will also C<croak> if the
target peer is fully removed from the bus while the request is
outstanding.

For protocols that support suspend/reconnect (see
C<suspend_supported> in L<IPC::Manager::Client>), a peer that has
merely suspended or restarted under a new process id is B<not> treated
as gone: the call keeps waiting, because a response can still arrive
once the peer resumes.  Only full unregistration (C<peer_exists>
false) triggers the peer-went-away error.  For protocols without
suspend support, a dead process id counts as gone.

=item $res = $self->await_response($id)

=item $res = $self->await_response($id, $timeout)

Waits for a response to a request. Returns the response when available.

Honors the same C<$timeout> and peer-death semantics as C<sync_request>.

=item $self->await_all_responses()

Waits for all pending responses to arrive.

=item @messages = $self->messages()

Returns and clears the message buffer.

=item $self->poll()

=item $self->poll($timeout)

Polls for messages. Returns the number of messages received.

If C<$timeout> is provided, waits up to that many seconds for messages.

=back

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

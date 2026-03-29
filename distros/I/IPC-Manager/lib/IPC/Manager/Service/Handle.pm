package IPC::Manager::Service::Handle;
use strict;
use warnings;

our $VERSION = '0.000007';

use Carp qw/croak/;
use Time::HiRes qw/sleep time/;
use Test2::Util::UUID qw/gen_uuid/;

use Role::Tiny::With;

with 'IPC::Manager::Role::Service::Select';
with 'IPC::Manager::Role::Service::Requests';

use Object::HashBase qw{
    <service_name
    <name
    <ipcm_info

    interval

    +client

    +request_callbacks
    +requests

    +buffer
};

sub init {
    my $self = shift;

    $self->clear_servicerequests_fields;
    $self->clear_serviceselect_fields;

    croak "'service_name' is a required attribute" unless $self->{+SERVICE_NAME};
    croak "'ipcm_info' is a required attribute" unless $self->{+IPCM_INFO};

    $self->{+INTERVAL} //= 0.2;

    $self->{+NAME} //= gen_uuid();
}

sub select_handles {
    my $self   = shift;
    my $client = $self->client;
    return $client->have_handles_for_select ? $client->handles_for_select : ();
}

sub ready {
    my $self = shift;
    $self->client->peer_active($self->{+SERVICE_NAME});
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
    my $id = $self->send_request(@_);
    return $self->await_response($id);
}

sub await_response {
    my $self = shift;
    my ($id) = @_;

    while (1) {
        my @out = $self->get_response($id);
        return $out[0] if @out;

        $self->poll();
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

            sleep $self->{+INTERVAL};
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

Returns true if the handle is ready to use

=item $client = $self->client()

Returns the client connection, creating it if necessary.

=item $pid = $self->service_pid()

Returns the PID of the peer service.

=item $res = $self->sync_request($req)

Sends a request and waits for the response. Returns the response.

=item $res = $self->await_response($id)

Waits for a response to a request. Returns the response when available.

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

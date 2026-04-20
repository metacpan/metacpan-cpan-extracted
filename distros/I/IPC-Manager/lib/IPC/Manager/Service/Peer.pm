package IPC::Manager::Service::Peer;
use strict;
use warnings;

our $VERSION = '0.000027';

use Carp qw/croak/;
use Scalar::Util qw/weaken/;

use Object::HashBase qw{
    <name
    <service
};

sub init {
    my $self = shift;

    croak "'name' is required" unless $self->{+NAME};

    my $service = $self->{+SERVICE} or croak "'service' is required";

    croak "'service' must be the current process" unless $service->pid == $$;

    weaken($self->{+SERVICE});

    return;
}

sub ready {
    my $self = shift;
    my ($timeout) = @_;
    $self->{+SERVICE}->client->peer_active($self->{+NAME}, $timeout);
}

sub send_request {
    my $self = shift;
    my ($req, $cb) = @_;
    $self->{+SERVICE}->send_request($self->{+NAME}, $req, $cb);
}

sub get_response {
    my $self = shift;
    my ($id) = @_;
    $self->{+SERVICE}->get_response($id);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Service::Peer - Peer connection class for L<IPC::Manager> services

=head1 DESCRIPTION

This class represents a connection to another service in the IPC system.
It provides methods to send requests and get responses through the parent
service's client connection.

=head1 SYNOPSIS

    my $peer = IPC::Manager::Service::Peer->new(
        name    => 'other-service',
        service => $service_obj,
    );

    # Check if peer is ready
    if ($peer->ready) {
        # Send a request
        my $id = $peer->send_request({action => 'do_something'});

        # Get a response (non-blocking)
        if (my $response = $peer->get_response($id)) {
            ...
        }
    }

=head1 ATTRIBUTES

=over 4

=item name

The name of the peer service (required).

=item service

The parent service object (required). Must be running in the current process.

=back

=head1 METHODS

=over 4

=item $bool = $self->ready()

=item $bool = $self->ready($timeout)

Check if the peer is ready for requests.

With no argument (or C<undef>), C<ready> returns the current state
immediately (one-shot, backwards-compatible).

With C<$timeout>, C<ready> blocks until the peer becomes active or the
timeout elapses, whichever comes first.  A C<$timeout> of C<0> blocks
indefinitely until the peer is ready.

When the underlying client protocol exposes a peer-change file descriptor
(C<have_handles_for_peer_change>, e.g. inotify on the FS-based protocols),
C<ready> waits on that descriptor via C<IO::Select>; otherwise it falls
back to a short sub-second sleep and retry.

=item $id = $self->send_request($req)

=item $self->send_request($req, $cb)

Sends a request to the peer. C<$req> is the request data, C<$cb> is an
optional callback for async responses.

Returns the request ID.

=item $res = $self->get_response($id)

Gets a response for a previously sent request.

If the response is ready it is returned, otherwise undef is returned.

Exceptions will be thrown if the $id is invalid, or if the response has already
been fetched.

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

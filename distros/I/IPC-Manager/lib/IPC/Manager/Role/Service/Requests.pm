package IPC::Manager::Role::Service::Requests;
use strict;
use warnings;

our $VERSION = '0.000009';

# Not included in role:
use Carp qw/croak/;
use List::Util qw/any/;
use Test2::Util::UUID qw/gen_uuid/;

use Role::Tiny;

requires qw{
    client
};

sub clear_servicerequests_fields {
    my $self = shift;
    delete $self->{_RESPONSES};
    delete $self->{_RESPONSE_HANDLER};
}

sub have_pending_responses {
    my $self = shift;

    return 1 if $self->{_RESPONSES}        && any { !defined($_) } values %{$self->{_RESPONSES}};
    return 1 if $self->{_RESPONSE_HANDLER} && any { defined($_) } values %{$self->{_RESPONSE_HANDLER}};
    return 0;
}

sub handle_response {
    my $self = shift;
    my ($resp, $msg) = @_;

    my $id = $resp->{ipcm_response_id};

    if (my $handler = delete $self->{_RESPONSE_HANDLER}->{$id}) {
        $handler->($resp, $msg);
    }
    else {
        croak "Got an unexpected response for '$id'" unless exists $self->{_RESPONSES}->{$id};
        croak "Got an extra response for '$id'" if defined $self->{_RESPONSES}->{$id};
        $self->{_RESPONSES}->{$id} = $resp;
    }

    return;
}

sub send_request {
    my $self = shift;
    my ($peer, $req, $cb) = @_;

    my $id = gen_uuid();

    $self->client->send_message(
        $peer,
        {
            ipcm_request_id => $id,
            request         => $req,
        }
    );

    if ($cb) {
        $self->{_RESPONSE_HANDLER}->{$id} = $cb;
    }
    else {
        $self->{_RESPONSES}->{$id} = undef;
    }

    return $id;
}

sub get_response {
    my $self = shift;
    my ($resp_id) = @_;

    my $resps = $self->{_RESPONSES} // {};

    croak "Response id '$resp_id' has a callback assigned, cannot use both get_response() and a callback"
        if exists $self->{_RESPONSE_HANDLER}->{$resp_id};

    croak "Not expecting a response with id '$resp_id'"
        unless exists $resps->{$resp_id};

    return undef unless defined $resps->{$resp_id};
    return delete $resps->{$resp_id};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Role::Service::Requests - Role for handling request/response patterns in IPC services.

=head1 DESCRIPTION

This role provides functionality for sending requests and handling responses in a
request/response pattern over IPC connections. It tracks pending responses and
supports both callback-based and blocking response retrieval.

=head1 SYNOPSIS

    package MyService;
    use Role::Tiny;
    with 'IPC::Manager::Role::Service::Requests';

    sub client { ... }  # Returns a client object

    # Send a request with a callback
    my $id = $service->send_request($peer => $request => sub {
        my ($resp, $msg) = @_;
        # Handle response
    });

    # Send a request and get response later
    $id = $service->send_request($peer => $request);

    # Get the response (blocks until available)
    my $response = $service->get_response($id);

    # Check if there are pending responses
    if ($service->have_pending_responses) {
        # ...
    }

=head1 METHODS

=over 4

=item $service->clear_servicerequests_fields()

Clears all internal response tracking fields. Call this when resetting or
reinitializing the service.

=item $bool = $service->have_pending_responses()

Returns true if there are pending responses either waiting in the response hash
or with active callbacks.

=item $service->handle_response($resp, $msg)

Handles an incoming response message. If the response has an associated callback,
it will be executed. Otherwise, the response is stored for later retrieval with
C<get_response()>.

=item $id = $service->send_request($peer, $request, $cb)

Sends a request to the specified peer. If a callback C<$cb> is provided, it will
be called when the response arrives. If no callback is provided, the response
can be retrieved later with C<get_response()>.

Returns the unique request ID.

=item $response = $service->get_response($resp_id)

Retrieves the response for the given response ID. If the response is not yet
available, returns undef. Throws an exception if the ID has a callback assigned
or if no response was ever requested with that ID.

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

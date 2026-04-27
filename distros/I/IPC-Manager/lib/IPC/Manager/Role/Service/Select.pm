package IPC::Manager::Role::Service::Select;
use strict;
use warnings;

our $VERSION = '0.000035';

# Not included in role:
use Carp qw/croak/;

use Role::Tiny;

requires qw{
    select_handles
};

sub clear_serviceselect_fields {
    my $self = shift;
    delete $self->{_SELECT};
}

# Returns true when the underlying client multiplexes a handle set that may
# change during normal operation (e.g. accepted SOCK_STREAM connections).
# Defaults to consulting the client; consumers that don't have a client
# accessor get the safe answer (false).
sub have_dynamic_handles_for_select {
    my $self = shift;
    return 0 unless $self->can('client');
    my $client = $self->client or return 0;
    return 0 unless $client->can('have_dynamic_handles_for_select');
    return $client->have_dynamic_handles_for_select ? 1 : 0;
}

sub select {
    my $self = shift;

    my $dynamic = $self->have_dynamic_handles_for_select;

    return $self->{_SELECT} if !$dynamic && exists $self->{_SELECT};

    my @handles = $self->select_handles;
    unless (@handles) {
        $self->{_SELECT} = undef unless $dynamic;
        return undef;
    }

    require IO::Select;
    my $s = IO::Select->new;
    $s->add(@handles);

    $self->{_SELECT} = $s unless $dynamic;
    return $s;
}

# Build a fresh IO::Select for the client's writable handles, or
# return undef when no peer has a backlog. Built fresh per call
# because the writable-handle set tracks the outbox, which is
# transient by design.
sub select_write {
    my $self = shift;
    my $client = $self->client;

    return undef unless $client->have_writable_handles;

    my @handles = $client->writable_handles;
    return undef unless @handles;

    require IO::Select;
    my $s = IO::Select->new;
    $s->add(@handles);
    return $s;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Role::Service::Select - Role for I/O multiplexing in IPC services

=head1 DESCRIPTION

This role provides I/O multiplexing functionality using L<IO::Select> for
IPC services. It manages filehandles and provides a C<select()> method
that returns an IO::Select object.

=head1 REQUIRED METHODS

The consuming class must implement:

=over 4

=item $self->select_handles()

Returns a list of filehandles to monitor for I/O.

=back

=head1 METHODS

=over 4

=item $self->clear_serviceselect_fields()

Clears the internal select object cache.

=item $self->select()

Returns an IO::Select object for the service's handles. Creates one if
necessary. Returns undef if there are no handles.

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

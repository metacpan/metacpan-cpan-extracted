package IPC::Manager::Base::FS::Handle;
use strict;
use warnings;

our $VERSION = '0.000018';

use Carp qw/croak/;

use parent 'IPC::Manager::Base::FS';
use Object::HashBase qw{
    +buffer
};

sub fill_buffer { croak "Not Implemented" }

sub pending_messages {
    my $self = shift;

    $self->pid_check;

    return 1 if $self->have_resume_file;
    return 1 if @{$self->{+BUFFER} // []};

    if ($self->can_select) {
        return 1 if $self->select->can_read(0);
    }
    else {
        return 1 if $self->fill_buffer;
    }

    return 0;
}

sub ready_messages {
    my $self = shift;

    $self->pid_check;

    return 1 if $self->have_resume_file;
    return 1 if @{$self->{+BUFFER} // []};

    return 0 unless $self->pending_messages;

    return 1 if $self->fill_buffer;

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Base::FS::Handle - Base class for filesystem clients that read via a handle

=head1 DESCRIPTION

This is an intermediate base class for filesystem-based protocol clients that
receive messages through a filehandle (such as a FIFO pipe or a Unix socket).
It extends L<IPC::Manager::Base::FS> and provides C<pending_messages> and
C<ready_messages> implementations built on top of a buffering primitive.

Subclasses must implement C<fill_buffer>.

=head1 METHODS

See L<IPC::Manager::Base::FS> and L<IPC::Manager::Client> for inherited methods.

=over 4

=item $bool = $con->fill_buffer

Read available data from the underlying handle into the internal message
buffer.  Returns true if at least one message was placed in the buffer.

This method must be implemented by subclasses; the base implementation dies
with "Not Implemented".

=item $bool = $con->pending_messages

Returns true if there are messages that appear to be incoming but may not yet
be fully readable.  Checks (in order): a resume file, the in-memory buffer,
and — if C<IO::Select> is available — whether the handle is ready for
reading, otherwise calls C<fill_buffer>.

=item $bool = $con->ready_messages

Returns true if there is at least one complete message that can be returned
immediately by C<get_messages>.  Checks the resume file and buffer first;
if neither has data it calls C<pending_messages> then C<fill_buffer> to
determine whether a message can be made available.

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

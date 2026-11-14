package LibTmux::CommandResult;
use v5.44;
sub stdout     ($self) { $self->{stdout} }
sub stderr     ($self) { $self->{stderr} }
sub exit_code  ($self) { $self->{exit_code} }
sub signal     ($self) { $self->{signal} }
sub raw_status ($self) { $self->{raw_status} }

sub success ($self) {
    defined($self->raw_status) && $self->exit_code == 0 && $self->signal == 0;
}

=head1 NAME

LibTmux::CommandResult - Completed or partial subprocess outcome

=head1 METHODS

=head2 stdout

Return retained stdout octets, possibly empty. No text decoding occurs.

=head2 stderr

Return separately retained stderr octets, possibly empty.

=head2 exit_code

Return an exit code or undef when no child status is known.

=head2 signal

Return a terminating signal number, zero for ordinary exit, or undef for unknown status.

=head2 raw_status

Return the POSIX wait status or undef when unavailable.

=head2 success

Return true only when known status proves ordinary exit zero. Unknown status is never success.

=head1 OWNERSHIP

Readers are local and do not mutate the result or perform I/O. A lifecycle
exception may expose a bounded partial result; it does not imply rollback or
command completion. See L<LibTmux::Transport/run> and L<LibTmux::X>.

=cut

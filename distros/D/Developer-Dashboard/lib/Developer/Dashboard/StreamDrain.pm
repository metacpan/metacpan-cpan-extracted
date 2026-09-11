package Developer::Dashboard::StreamDrain;

use strict;
use warnings;

our $VERSION = '4.31';

use Exporter 'import';

our @EXPORT_OK = qw(_drain_ready_handle);

# Exported into the consuming package rather than called as a class method, so
# every call site reads as $self->_drain_ready_handle(...) and Perl resolves it
# through the consumer's own symbol table. That matters: it keeps the helper
# mockable from each consumer's tests, which is the seam DD-615 learned to
# preserve the hard way - a helper called as a plain function resolves in the
# module it lives in, so a test patching only the consumer stops reaching it.

# _drain_ready_handle($selector, $handle)
# Reads one ready handle from a select set, exactly as the two inline readers
# did before this was shared.
# Input: the IO::Select object and the handle it reported ready.
# Output: a reference to the bytes read, or undef when the handle is finished -
#         in which case it has already been removed from the selector and closed.
sub _drain_ready_handle {
    my ( $self, $selector, $handle ) = @_;

    # THREE OUTCOMES, NOT TWO (DD-678). sysread returns 0 at end of file and
    # undef on error, and this used to take the same branch for both - which
    # meant an interrupted read closed the handle and silently truncated the
    # child's output.
    #
    # Perl does not install handlers with SA_RESTART, and sysread bypasses the
    # :perlio layer that would otherwise retry, so EINTR reaches us. SkillManager
    # raises SIGALRM itself, so this is not hypothetical for its own reader.
    #
    # PageRuntime does not share this helper - it already had its own EINTR-aware
    # drain, and adopting a non-aware one would have been a regression. That is
    # now moot in the sense that this one is aware too, but the separation stays:
    # t/163 fails by design if anybody migrates it.
    #
    # AND IT HANDLES EINTR DIFFERENTLY, deliberately, because the two helpers
    # return different things. PageRuntime's _drain_saved_ajax_ready_handle
    # returns a STATUS and can therefore do an early "return 1" on EINTR -
    # phrased without backticks or the literal exit-status variable, because
    # t/159's guard sweeps RAW SOURCE and cannot tell code from the commentary
    # about it: a backtick pair anywhere in a sub body reads as a command
    # substitution, and naming that variable at all reads as an unguarded use.
    # Both fire from inside a comment. Filed as DD-693. Handing
    # control back so its outer select loop calls again. This one returns DATA,
    # with undef meaning "the handle is finished", so returning undef on EINTR
    # would reproduce the very defect being fixed. The retry therefore happens
    # here, in a loop.
    #
    # That loop cannot busy-spin: sysread on a blocking handle waits for bytes or
    # a signal, so between interrupts it is asleep, not turning. It is the
    # standard EINTR idiom, not a poll.
    my $chunk = '';
    my $read;

    while (1) {
        $read = sysread( $handle, $chunk, 8192 );
        last if defined $read;

        # RETRYABLE. The read was interrupted before any bytes moved; the child
        # is not finished and the handle is still live.
        next if $!{EINTR};

        # A GENUINE ERROR, which is neither retryable nor end of file. It is
        # surfaced rather than swallowed - reporting it as EOF is what hid this
        # class of failure in the first place - and then the handle is finished,
        # because a handle we cannot read is not one we can keep selecting on.
        warn "reading a ready child handle failed: $!\n";
        last;
    }

    if ( !defined $read || $read == 0 ) {
        $selector->remove($handle);
        close $handle;
        return;
    }

    return \$chunk;
}

1;

__END__

=head1 NAME

Developer::Dashboard::StreamDrain - the one place a ready handle is read

=head1 PURPOSE

Provide the single inner drain step shared by the dashboard's inline
streaming child-process readers: read up to 8192 bytes from a handle that
L<IO::Select> reported ready, and, when the handle is finished, remove it from
the select set and close it.

=head1 WHY IT EXISTS

C<SkillDispatcher> and C<SkillManager> each carried a byte-identical copy of
this step. Copy-paste was provable rather than inferred: both files carried the
same authored C<# uncoverable condition left> annotation on the same end-of-file
branch. A bug in that step therefore had to be found and fixed twice, and this
project has already paid that cost - the C<$?>-pollution defect in the same
family of readers was fixed through two unrelated ticket series before a
standing sweep was added to police it.

It exists as its own module rather than as a method on a base class because the
callers share nothing else: they differ in timeout policy, in what a timeout
does, in where the bytes go, and in where the exit status comes from. Only this
step is common, and only this step is shared.

C<PageRuntime> is deliberately NOT a consumer. It had already factored its own
read out and guards C<EINTR>, which this helper does not; importing this one
would replace a correct drain with a defective one.

=head1 WHEN TO USE

Whenever a caller reads a child process's C<stdout> or C<stderr> through
C<IO::Select> and wants the established end-of-file handling. Callers keep
their own loop, their own timeout policy and their own accounting.

=head1 HOW TO USE

    use Developer::Dashboard::StreamDrain qw(_drain_ready_handle);

    while ( my @ready = $selector->can_read ) {
        for my $handle (@ready) {
            my $chunk_ref = $self->_drain_ready_handle( $selector, $handle )
                or next;                      # finished: already removed and closed
            # ... route ${$chunk_ref} wherever this caller sends it ...
        }
    }

=head1 WHAT USES IT

C<Developer::Dashboard::SkillDispatcher> and
C<Developer::Dashboard::SkillManager>.

=head1 EXAMPLES

Routing by file descriptor, as C<SkillDispatcher> does when it tees a child's
output through to the real C<STDOUT> and C<STDERR>:

    my $chunk_ref = $self->_drain_ready_handle( $selector, $fh ) or next;
    if ( fileno($fh) == $stdout_fd ) {
        print STDOUT ${$chunk_ref};
        $stdout_text .= ${$chunk_ref};
        next;
    }

Accumulating into a per-handle slot, as C<SkillManager> does while reporting
progress a line at a time:

    my $chunk_ref = $self->_drain_ready_handle( $selector, $handle ) or next;
    my $slot = $target_for{ fileno($handle) };
    ${$slot} .= ${$chunk_ref} if $slot;

=cut

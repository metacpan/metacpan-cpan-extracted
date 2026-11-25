package Developer::Dashboard::StreamDrain;

use strict;
use warnings;

our $VERSION = '6.31';

use Exporter 'import';
use Time::HiRes ();

our @EXPORT_OK = qw(_drain_ready_handle _drain_child_streams_windows);

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

# _drain_child_streams_windows($stdout, $stderr, $on_chunk, $deadline)
# Drains two open3 pipe handles on Windows, where IO::Select cannot see
# pipes at all: select() there only works for real sockets, so a can_read
# loop over pipe handles returns at once with nothing ready and the child's
# output is silently lost (the doctor hook proved it live: the hook ran and
# exited 0, but its stdout arrived empty). Readiness comes from
# PeekNamedPipe on each pipe's real Win32 HANDLE, taken from
# Win32API::File::GetOsFHandle with the filehandle glob: passing the fileno
# number instead returns nothing, which is what the earlier version mistook
# for PeekNamedPipe being unusable on these pipes. The loop runs entirely
# in the main thread, exactly as PageRuntime already drains its Windows
# pipes, and it creates no reader threads: creating any ithread breaks
# later JSON::XS boolean encoding in the same process (proven on Strawberry
# Perl with a trivial thread: encode_json of a hash holding JSON::XS::true()
# dies afterwards, while the pure-Perl encoder still encodes and Perl-level isa still
# holds), and every streaming caller in this codebase encodes JSON booleans
# after the child returns. Chunks reach the callback in poll order, stdout
# first each round; order within one stream is preserved, so callers keep
# their streaming behaviour.
# Input: stdout handle, stderr handle, callback taking ($is_stdout, $chunk),
# and an optional deadline as epoch seconds (from Time::HiRes::time()): when
# given, the drain dies with the streaming timeout marker once the deadline
# passes, so a hung child is ended on time even though alarm delivery is
# deferred while this process is blocked in select on Strawberry Perl.
# Output: 1 when both handles were drained to end of file, 0 when the
# Windows primitive was unavailable, in which case the caller falls back
# to its select loop (the pre-existing behaviour, never a new failure).
sub _drain_child_streams_windows {
    my ( $self, $stdout, $stderr, $on_chunk, $deadline ) = @_;

    # PeekNamedPipe lives in kernel32; GetOsFHandle in Win32API::File. Both
    # are Windows-only core modules, loaded lazily here so this file still
    # compiles and runs on POSIX perls, where the callers never invoke this
    # function except under a mocked platform in tests.
    my $peek = eval {
        require Win32API::File;
        require Win32::API;
        my $imported = Win32::API->new( 'kernel32', 'PeekNamedPipe', 'QPIPPP', 'I' );
        die "Could not import PeekNamedPipe from kernel32\n" if !defined $imported;
        $imported;
    };
    return 0 if !$peek;

    # Resolve both Win32 HANDLEs up front: a handle PeekNamedPipe cannot
    # reach is a drain this function cannot run, not a handle to guess at
    # with a blocking read, which would stall the other stream.
    my @streams;
    for my $stream ( [ 1, $stdout ], [ 0, $stderr ] ) {
        my ( $is_stdout, $fh ) = @{$stream};
        return 0 if !defined $fh || !defined fileno($fh);
        my $handle = Win32API::File::GetOsFHandle($fh);
        return 0 if !defined $handle;
        push @streams, { is_stdout => $is_stdout, fh => $fh, handle => $handle, done => 0 };
    }

    # Poll both pipes until each reaches end of file. A pipe whose peek
    # reports bytes is read at once; a pipe with nothing buffered waits for
    # the next round; a pipe whose peek fails is broken, so the read that
    # follows can only return buffered bytes or end of file, never block.
    # The handles are left open for the caller, exactly as the thread drain
    # left them.
    while ( grep { !$_->{done} } @streams ) {
        # A caller-supplied deadline ends a hung child without waiting for
        # the SIGALRM that is supposed to do it: alarm delivery is deferred
        # while this process is blocked in select on Strawberry Perl (a bare
        # alarm(1) never fired in 25s of 1s selects, while the same alarm
        # fires at once in a busy loop), so a timeout that only relied on
        # alarm would return after ~17s instead of on time. The marker is
        # the same one the SIGALRM handler dies with, so the caller's eval
        # treats it identically.
        die "__STREAMING_COMMAND_TIMEOUT__\n"
          if defined $deadline && Time::HiRes::time() >= $deadline;
        my $progress = 0;
        for my $stream (@streams) {
            next if $stream->{done};
            my $avail = _windows_pipe_available( $peek, $stream->{handle} );
            $avail = -1 if !defined $avail;
            next if $avail == 0;
            my $chunk = '';
            my $read;
            while (1) {
                $read = sysread( $stream->{fh}, $chunk, 8192 );
                last if defined $read;
                next if $!{EINTR};
                warn "reading a child handle failed: $!\n";
                last;
            }
            if ( !defined $read || $read == 0 ) {
                $stream->{done} = 1;
                $progress = 1;
                next;
            }
            $progress = 1;
            $on_chunk->( $stream->{is_stdout}, $chunk );
        }
        select( undef, undef, undef, 0.02 ) if !$progress;
    }

    return 1;
}

# _windows_pipe_available($peek, $handle)
# Reports how many bytes are waiting on one Windows pipe, without blocking.
# Input: imported PeekNamedPipe function object and one real Win32 HANDLE.
# Output: byte count, or undef when the pipe is broken or the call fails.
sub _windows_pipe_available {
    my ( $peek, $handle ) = @_;
    return undef if !defined $handle;
    $^E = 0;
    my $bytes_read  = pack 'L', 0;
    my $total_avail = pack 'L', 0;
    my $bytes_left  = pack 'L', 0;
    my $ok = $peek->Call( $handle, '', 0, $bytes_read, $total_avail, $bytes_left );
    return undef if !$ok;
    return unpack 'L', $total_avail;
}

1;

__END__

=head1 NAME

Developer::Dashboard::StreamDrain - the one place a ready handle is read

=head1 PURPOSE

Provide the single inner drain step shared by the dashboard's inline
streaming child-process readers: read up to 8192 bytes from a handle that
L<IO::Select> reported ready, and, when the handle is finished, remove it from
the select set and close it. On Windows, where L<IO::Select> cannot see pipes
at all, provide the matching whole-loop drain that polls each child pipe with
C<PeekNamedPipe> in the main thread instead, so the same callers do not
silently lose the child's output there.

=head1 WHY IT EXISTS

C<SkillDispatcher> and C<SkillManager> each carried a byte-identical copy of
this step. Copy-paste was provable rather than inferred: both files carried the
same authored coverage-exemption annotation on the same end-of-file
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
would replace a correct drain with a defective one. It also already has its own
Windows path (a C<PeekNamedPipe> readiness loop in the main thread) - the pattern the whole-loop
drain here follows - so it never needed this module's version either.

=head1 WHEN TO USE

Whenever a caller reads a child process's C<stdout> or C<stderr> through
C<IO::Select> and wants the established end-of-file handling. Callers keep
their own loop, their own timeout policy and their own accounting. On Windows,
call C<_drain_child_streams_windows> instead of the select loop: C<select()>
there only works for real sockets, so a C<can_read> loop over pipe handles
returns at once with nothing ready and the child's output is lost.

=head1 HOW TO USE

    use Developer::Dashboard::StreamDrain qw(_drain_ready_handle);

    while ( my @ready = $selector->can_read ) {
        for my $handle (@ready) {
            my $chunk_ref = $self->_drain_ready_handle( $selector, $handle )
                or next;                      # finished: already removed and closed
            # ... route ${$chunk_ref} wherever this caller sends it ...
        }
    }

On Windows, use the whole-loop drain instead of the select loop above:

    use Developer::Dashboard::StreamDrain qw(_drain_child_streams_windows);

    my $drained = $self->_drain_child_streams_windows(
        $stdout, $stderr,
        sub {
            my ( $is_stdout, $chunk ) = @_;
            # ... route $chunk wherever this caller sends it ...
        },
        $deadline,    # optional epoch seconds; the drain dies with the
                      # streaming timeout marker once the deadline passes
    );
    # $drained is 1 when both streams reached end of file, 0 when the
    # Windows primitive was unavailable - fall back to the select loop.

=head1 WHAT USES IT

C<Developer::Dashboard::SkillDispatcher>,
C<Developer::Dashboard::SkillManager>, and the C<d2> switchboard's own
C<_run_command_hook_streaming> (which runs per-command and main-gate hooks
before the command itself).

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

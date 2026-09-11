#!/usr/bin/env perl

# TS-1 for DD-617, written and run GREEN against UNMODIFIED master before any
# extraction. That order is the point of the file.
#
# A test written after a refactor can only report that the code passes its own
# new expectations. Written first and confirmed green on the pre-change tree, it
# reports something else entirely: that the behaviour it pins is the behaviour
# that was already there. Without the "before" run, "preserved" and "never
# checked" are indistinguishable.
#
# WHAT IT PINS, AND WHY THESE FIVE THINGS
#
# Three modules stream a child process's stdout and stderr through IPC::Open3
# and IO::Select. Their INNER drain step is byte-equivalent and is the part
# DD-617 will share. Their OUTER control flow legitimately differs on five axes,
# and collapsing any one of them into a shared implementation would change some
# caller's behaviour WHILE EVERY EXISTING TEST STILL PASSED - because each
# module's tests only assert its own behaviour, so none of them can see that
# another module's has been altered to match it.
#
# That is not hypothetical. DD-615 extracted fourteen helpers whose bodies were
# byte-identical, and still shipped two defects invisible to a green suite: a
# dropped Time::HiRes import that silently disabled a Windows backoff, and four
# "uncoverable" annotations that became false claims once the extraction made
# their branches reachable.
#
# LIMIT OF THIS FILE, STATED RATHER THAN IMPLIED: these are structural
# assertions over source text, not behavioural ones. They catch a flattening -
# somebody replacing three timeout policies with one - which is the specific
# risk DD-617 carries. They do NOT prove the readers behave correctly; the
# per-module coverage tests do that. A structural guard is the right instrument
# here precisely because the failure being guarded against is "this code no
# longer exists in this module".

use strict;
use warnings;

use File::Spec;
use FindBin qw($RealBin);
use Test::More;

# _code_only($path)
# Returns a module's source with POD, __END__ onwards, whole-line comments and
# trailing comments removed.
#
# Comments MUST be stripped before asserting on source text. This file's own
# subject matter is discussed in comments inside the very modules it inspects -
# PageRuntime explains its post-exit drain in prose that names the constructs
# below - so a guard reading raw source cannot tell code from the commentary
# about the code, and would fire on an explanation rather than a change.
#
# Input: file path string.
# Output: source text containing code only.
sub _code_only {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my @lines = <$fh>;
    close $fh or die "Unable to close $path: $!";

    my @code;
    my $in_pod = 0;
    for my $line (@lines) {
        last if $line =~ /\A __(?:END|DATA)__ \s* \z/x;
        $in_pod = 1 if $line =~ /\A =\w+ /x;
        if ($in_pod) {
            $in_pod = 0 if $line =~ /\A =cut \b/x;
            next;
        }
        next if $line =~ /\A \s* \# /x;
        $line =~ s/ \s \# .* \z //x;
        push @code, $line;
    }
    return join q{}, @code;
}

my $LIB = File::Spec->catdir( $RealBin, File::Spec->updir, 'lib', 'Developer', 'Dashboard' );

my %SOURCE = (
    SkillDispatcher => _code_only( File::Spec->catfile( $LIB, 'SkillDispatcher.pm' ) ),
    SkillManager    => _code_only( File::Spec->catfile( $LIB, 'SkillManager.pm' ) ),
    PageRuntime     => _code_only( File::Spec->catfile( $LIB, 'PageRuntime.pm' ) ),
    StreamDrain     => _code_only( File::Spec->catfile( $LIB, 'StreamDrain.pm' ) ),
    WebServer       => _code_only( File::Spec->catfile( $LIB, 'Web', 'Server.pm' ) ),
);

# The shared inner step - and it is shared by TWO modules, not three.
#
# This assertion originally covered all three and FAILED on PageRuntime, which
# is how the premise got corrected before any code moved. PageRuntime has
# already factored its read into _stream_sysread and guards EINTR explicitly;
# only SkillDispatcher and SkillManager carry the raw inline form. So DD-617
# shares that step between two callers, with PageRuntime as the reference
# implementation rather than a third consumer.
# UPDATED IN THE SAME COMMIT AS THE BEHAVIOUR, which is what this file's own
# documentation requires. Before the extraction both consumers carried the
# inline 8192-byte sysread; now it lives once in StreamDrain and they call it.
# The assertion moves with the code rather than being deleted, so the step is
# still pinned - just pinned in its new home.
for my $mod (qw(SkillDispatcher SkillManager)) {
    like( $SOURCE{$mod}, qr/_drain_ready_handle\(\s*\$selector\s*,/,
        "$mod drains through the shared _drain_ready_handle" );
    unlike( $SOURCE{$mod}, qr/sysread\(\s*\$\w+\s*,\s*\$\w+\s*,\s*8192\s*\)/,
        "$mod no longer carries its own inline sysread" );
}
like( $SOURCE{StreamDrain}, qr/sysread\(\s*\$\w+\s*,\s*\$\w+\s*,\s*8192\s*\)/,
    'StreamDrain is now the one place the 8192-byte read happens' );

like( $SOURCE{PageRuntime}, qr/sub\s+_stream_sysread/,
    'PageRuntime has already factored its read into _stream_sysread' );

# DD-678, FIXED - and these assertions were RE-DESCRIBED rather than deleted,
# because what they test is still worth testing and is not what they said.
#
# They were written to pin the unfixed conflation "so that fixing it is a
# visible, deliberate change here rather than a silent side effect". They
# stopped doing that the moment DD-617's extraction landed: they grep the two
# CONSUMERS' source, and the drain moved out of both. Measured at the time of
# the fix - SkillDispatcher 0 occurrences of EINTR, SkillManager 0, StreamDrain
# 3. So the fix could have landed in StreamDrain with these still passing,
# unchanged, which is exactly the invisibility they existed to prevent.
#
# The behavioural pin now lives in t/177-stream-drain-eintr.t, which asserts
# what the shared helper DOES and therefore cannot be invalidated by moving code
# between files.
#
# What these three still genuinely guard: PageRuntime keeps its own EINTR-aware
# read, and neither consumer re-implements a drain locally instead of calling
# the shared one. Both remain true and both would be real regressions.
like( $SOURCE{PageRuntime}, qr/\$!\{EINTR\}/,
    'PageRuntime retries an EINTR-interrupted read instead of treating it as EOF' );
unlike( $SOURCE{SkillDispatcher}, qr/EINTR/,
    'SkillDispatcher handles EINTR only through the shared drain, not with its own copy' );
unlike( $SOURCE{SkillManager}, qr/EINTR/,
    'SkillManager handles EINTR only through the shared drain, not with its own copy' );

# AXIS 1 + 2 - timeout policy and what a timeout does.
unlike( $SOURCE{SkillDispatcher}, qr/can_read\(\s*[\d.]+\s*\)/,
    'SkillDispatcher blocks on can_read with NO timeout argument' );

like( $SOURCE{SkillManager}, qr/\$SIG\{ALRM\}/,
    'SkillManager bounds its read with a SIGALRM wall-clock timeout' );
like( $SOURCE{SkillManager}, qr/_terminate_streaming_command/,
    'SkillManager terminates the child when that timeout fires' );

like( $SOURCE{PageRuntime}, qr/can_read\(\s*0\.25\s*\)/,
    'PageRuntime polls can_read with a 0.25s timeout' );
like( $SOURCE{PageRuntime}, qr/__DD_AJAX_STREAM_DISCONNECTED__/,
    'PageRuntime can abandon the stream when the client disconnects' );
like( $SOURCE{PageRuntime}, qr/_drain_saved_ajax_post_exit_handles/,
    'PageRuntime drains handles AFTER the child exits (Windows loses the final body otherwise)' );

# AXIS 3 - where the bytes go.
# These two originally matched qr/print\s+STDOUT\s+\$\w+/ and FAILED after the
# extraction - not because the tee was lost, but because the bytes now arrive as
# ${$chunk_ref} rather than a plain scalar, which \$\w+ does not match. The
# behaviour was verified intact by reading the migrated code BEFORE the pattern
# was touched; loosening an assertion to make a suite green is only legitimate
# when you have first established that the thing it guards still holds.
like( $SOURCE{SkillDispatcher}, qr/print\s+STDOUT\s+\$\{?\$?\w+\}?/,
    'SkillDispatcher tees child stdout through to the real STDOUT' );
like( $SOURCE{SkillDispatcher}, qr/print\s+STDERR\s+\$\{?\$?\w+\}?/,
    'SkillDispatcher tees child stderr through to the real STDERR' );
like( $SOURCE{SkillManager}, qr/_progress_detail_line/,
    'SkillManager reports progress per line instead of teeing' );

# AXIS 4 - where the exit status comes from.
like( $SOURCE{SkillDispatcher}, qr/exit_code\s*=>\s*\$\?\s*>>\s*8/,
    'SkillDispatcher reports $? >> 8 after waitpid' );
like( $SOURCE{SkillManager}, qr/\$timed_out\s*\?\s*-1\s*:\s*\$\?\s*>>\s*8/,
    'SkillManager reports -1 when it timed out, else $? >> 8' );

# The out-of-scope lookalike. A bare grep for IO::Select returns four files;
# this one is a socket proxy for the SSL front end, and DD-617 must not touch
# it. Pinned so that "extract every IO::Select user" fails here by design.
like( $SOURCE{WebServer}, qr/sub\s+_proxy_streams/,
    'Web::Server keeps its own socket proxy (NOT a child-process reader)' );
unlike( $SOURCE{WebServer}, qr/open3/,
    'Web::Server runs no child process, so it is out of DD-617 scope' );

done_testing();

__END__

=head1 NAME

t/162-streaming-reader-axes.t - pin the five axes on which the three streaming child readers legitimately differ

=head1 PURPOSE

Assert, per call site, the timeout policy, timeout action, output sink and
exit-status source that C<SkillDispatcher>, C<SkillManager> and C<PageRuntime>
each use today, together with the byte-equivalent inner drain step they share.

=head1 WHY IT EXISTS

DD-617 shares the inner drain step across those three modules. The risk is not
that the shared step is wrong - it is that the surrounding control flow gets
collapsed too, silently giving one module another's timeout policy or sink,
with every existing test still green because each module's tests only assert its
own behaviour.

It was written and confirmed passing BEFORE the extraction. A characterization
test written afterwards cannot distinguish behaviour that was preserved from
behaviour that was never checked.

=head1 WHEN TO USE

It runs in the ordinary suite. Consult it when changing how any of the three
modules reads a child process, or when adding a fourth such reader.

=head1 HOW TO USE

    prove -l t/162-streaming-reader-axes.t

A failure names the module and the axis. If the change was deliberate, the
assertion is updated in the same commit as the behaviour - never separately.

=head1 WHAT USES IT

Nothing programmatic; it is a standing guard run by C<prove -lr t> and by the
coverage gate.

=head1 EXAMPLES

Replacing C<PageRuntime>'s C<can_read(0.25)> poll with a blocking C<can_read>
fails here by design, because that would adopt C<SkillDispatcher>'s timeout
policy and lose the child-exit probe the saved-ajax path depends on.

Extending the extraction to C<Web::Server> also fails here: that module proxies
between two sockets and runs no child process, so it is deliberately excluded.

=cut

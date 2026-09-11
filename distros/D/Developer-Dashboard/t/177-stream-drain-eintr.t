#!/usr/bin/env perl

# Written RED, before StreamDrain distinguishes the three sysread outcomes.
#
# WHY THIS FILE EXISTS AT ALL, given t/162 claims to pin the same thing.
#
# StreamDrain's own comment says "t/162 pins the current behaviour so the fix
# has to arrive as a visible failing assertion rather than as a side effect."
# That was true when written and is not true now. t/162's pins are SOURCE-TEXT
# greps against SkillDispatcher and SkillManager:
#
#     unlike( $SOURCE{SkillDispatcher}, qr/EINTR/, '...pinned so the fix is deliberate' );
#
# DD-617 moved the drain OUT of both consumers. Measured on master before this
# change: SkillDispatcher 0 occurrences of EINTR, SkillManager 0, StreamDrain 3
# - all three inside the comment, none in code. So a fix to StreamDrain adds
# EINTR to StreamDrain alone, those two assertions keep passing unchanged, and
# the fix lands INVISIBLY - the exact outcome the pin existed to prevent.
#
# That is a shape worth naming: an assertion that was correct and discriminating
# when written, and was made vacuous FOR ITS STATED PURPOSE by a later,
# unrelated, entirely correct refactor. Nothing goes red. The suite stays green.
# Only the comment promising the protection survives, and it is believed.
#
# So this file pins the BEHAVIOUR instead of the source text, which is what
# cannot be silently invalidated by moving code between files.
#
# DETERMINISM. The interrupt is not raced against a child process. The ALRM
# handler itself writes the payload, so by the time an EINTR-aware retry runs,
# the data is guaranteed to be there. A run cannot pass or fail on timing.

use strict;
use warnings;

use Test::More;
use IO::Select;
use File::Spec;
use POSIX qw(EINTR);
use FindBin;
use lib "$FindBin::Bin/../lib";

require_ok('Developer::Dashboard::StreamDrain');

my $PAYLOAD = 'PAYLOAD-DELIVERED-AFTER-EINTR';

# Feature: an EINTR-interrupted read is retried, not mistaken for end of file.
#
# Scenario: a signal arrives while sysread is blocked on a handle that IO::Select
# reported ready. Given the signal handler writes the payload before returning,
# when the drain step runs, then it returns those bytes - because EINTR means
# "try again", not "the child is finished".
{
    pipe( my $reader, my $writer ) or BAIL_OUT("cannot pipe: $!");

    # The handler supplies the data, so the retry has something to find. This is
    # what makes the test deterministic rather than a race with a child process.
    local $SIG{ALRM} = sub { syswrite( $writer, $PAYLOAD ) };
    alarm 1;

    my $selector = IO::Select->new($reader);
    my $chunk_ref =
      Developer::Dashboard::StreamDrain::_drain_ready_handle( undef, $selector, $reader );
    alarm 0;

    ok( defined $chunk_ref,
        'an EINTR-interrupted read does not report end of file' )
      or diag(
        'the drain returned undef, which its callers read as "child finished" - '
      . 'so the payload written during the interrupt is silently discarded' );

    is( ( defined $chunk_ref ? ${$chunk_ref} : '' ), $PAYLOAD,
        'the bytes that arrived during the interrupt are returned intact' );

    ok( $selector->exists($reader),
        'the handle is still in the select set after an interrupted read' )
      or diag('an EINTR retry must not remove the handle - the child is not finished');

    close $reader if defined fileno $reader;
    close $writer;
}

# Scenario: a real end of file still closes silently.
# Given the writer is closed so sysread returns 0, when the drain step runs,
# then it returns undef and removes the handle - unchanged behaviour, asserted
# so the fix cannot achieve its goal by never closing anything.
{
    pipe( my $reader, my $writer ) or BAIL_OUT("cannot pipe: $!");
    close $writer;

    my $selector = IO::Select->new($reader);
    my $chunk_ref =
      Developer::Dashboard::StreamDrain::_drain_ready_handle( undef, $selector, $reader );

    ok( !defined $chunk_ref, 'a real EOF still reports the handle finished' );
    ok( !$selector->exists($reader), 'a real EOF still removes the handle from the select set' );
}

# Scenario: a genuine error is surfaced, not reported as end of file.
#
# Given a handle sysread cannot read from - here one opened write-only, which
# fails with EBADF rather than EINTR - when the drain step runs, then it warns
# naming the error and reports the handle finished. The warning is the point:
# swallowing this as EOF is what hid the whole class of failure, and a caller
# that sees a silent close cannot tell a finished child from a broken pipe.
{
    open( my $write_only, '>', File::Spec->devnull ) or BAIL_OUT("cannot open devnull: $!");

    my $selector = IO::Select->new();
    my $chunk_ref;
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $chunk_ref =
          Developer::Dashboard::StreamDrain::_drain_ready_handle( undef, $selector, $write_only );
    }

    ok( !defined $chunk_ref, 'a genuine read error reports the handle finished' );
    ok( scalar(@warnings), 'a genuine read error is WARNED about, not swallowed as EOF' )
      or diag('silently treating an error as EOF is the defect this card exists to fix');
    # Perl emits its own "opened only for output" warning first, so the check is
    # over ALL warnings rather than the first - asserting on $warnings[0] made
    # this fail for a reason that had nothing to do with the code under test.
    ok( scalar( grep { /reading a ready child handle failed/ } @warnings ),
        'the warning names what failed rather than only the errno' )
      or diag( 'warnings seen: ' . join '|', @warnings );
}

done_testing();

__END__

=head1 NAME

t/177-stream-drain-eintr.t - pin that StreamDrain tells EINTR apart from EOF

=head1 PURPOSE

Assert behaviourally that C<_drain_ready_handle> retries a read interrupted by a
signal and returns the bytes that arrived, while still treating a genuine
end of file as the handle being finished.

=head1 WHY IT EXISTS

C<sysread> returns 0 at end of file and undef on error, and the drain step used
to take the same branch for both. An interrupted read - EINTR, which is
retryable and which C<SkillManager> provokes itself by raising SIGALRM - was
therefore read as "the child is done", silently truncating its output.

It is a separate file from t/162 deliberately. t/162 pins the same concern by
grepping SkillDispatcher's and SkillManager's SOURCE, and DD-617 moved the drain
out of both, so those assertions can no longer fail however the shared helper
behaves. An assertion that survives the code it guards moving elsewhere is worse
than none, because the comment promising the protection is still believed.

=head1 WHEN TO USE

It runs in the ordinary suite. Consult it when changing how a ready handle is
read, or before assuming a truncated child output is the child's fault.

=head1 HOW TO USE

    prove -l t/177-stream-drain-eintr.t

=head1 WHAT USES IT

Nothing programmatic; it is a standing guard, run by C<prove -lr t> and by the
coverage gate.

=head1 EXAMPLES

Reverting C<_drain_ready_handle> to C<< if ( !defined $read || $read == 0 ) >>
makes the first scenario fail: the drain reports end of file, and the payload
written while the read was interrupted is lost.

=cut

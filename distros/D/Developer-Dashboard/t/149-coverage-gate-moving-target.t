#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Capture::Tiny qw(capture_merged);
use Cwd qw(getcwd);
use Fcntl qw(:flock);
use File::Spec;
use File::Temp qw(tempdir);

# A full gate reads t/ for tens of minutes. If the tree moves during that window
# - a branch switch, a worktree command, an editor saving a file - the run grades
# a mixture of two states and reports a number for neither. What makes it worth a
# check of its own is the failure mode rather than the untidiness: a test that
# fails because the tree moved looks exactly like a test that fails because the
# code is wrong, so the only safe response is to distrust the entire run.
#
# The real window is minutes wide, which cannot be raced honestly in a test. It
# can be staged exactly, though: the gate runs `prove` through PATH, so a
# stand-in `prove` that modifies t/ while it "runs" reproduces the hazard in a
# second, at the precise moment the real one occurs.

my $repository = getcwd();
my $gate       = File::Spec->catfile( $repository, 'script', 'coverage-gate' );

plan skip_all => "the coverage gate is not present at $gate" if !-f $gate;

# Devel::Cover is an optional development tool, not a declared runtime dependency.
# Without it the gate takes a different and correct path - it reports that
# Devel::Cover::DB::IO could not be loaded - so this file's subject cannot be
# measured at all, and its assertions would report an environmental gap as a
# defect. The guard sits BEFORE any plan is declared: t/151 previously died after
# 3 of a planned 9, and "Bad plan. You planned 9 tests but ran 3" cannot tell a
# reader which assertions were unmet and which were never attempted. Gated by
# t/170-optional-tooling-skips.t, because CI carries Devel::Cover and would never
# notice this guard being removed.
plan skip_all => 'Devel::Cover is not installed, so the coverage gate cannot be exercised'
  if !eval { require Devel::Cover::DB::IO; 1 };

plan tests => 6;

# Purpose: serialise this file against t/148-coverage-gate-entrypoint.t.
# Input: none. Output: an exclusive flock held for the life of this process.
# This file deliberately creates t/dd528-moving-target-probe.tmp while its
# own gate run is in progress, to prove the gate notices a moving tree.
# The gate fingerprints t/ and lib/ before and after the suite, so when
# prove -j runs both files at once, the probe can land inside t/148's
# fingerprint window and its gate refuses to report - a failure that looks
# like a defect in the gate but is only the two files racing each other.
# The gate already sequences these two files for the suites it runs
# itself; the outer harness (dzil test, prove -j) knows no such rule, so
# the files sequence themselves here instead, on the same lock t/148
# takes. The lock file lives in the system temp dir, never under t/ or
# lib/, so creating it cannot itself change the fingerprint. The handle
# is a file-scope lexical, never closed explicitly: the flock is released
# when the process exits, after END blocks run, so the probe is unlinked
# before the lock is released.
my $serial_lock_dir = File::Spec->tmpdir();
$serial_lock_dir = '.' if !defined $serial_lock_dir || !-d $serial_lock_dir;
my $serial_lock_path
  = File::Spec->catfile( $serial_lock_dir, 'developer-dashboard-coverage-gate-148-149.lock' );
open my $serial_lock_fh, '>>', $serial_lock_path
  or die "cannot open serial lock $serial_lock_path: $!";
flock $serial_lock_fh, LOCK_EX
  or die "cannot lock $serial_lock_path: $!";

my $probe = File::Spec->catfile( $repository, 't', 'dd528-moving-target-probe.tmp' );

# The probe is created inside the repository by the stubbed suite, so it must be
# removed however this file ends - including a die part way through. Leaving it
# behind would change what every later run grades, which is the defect under test.
END { unlink $probe if defined $probe }

my $moving_dir = tempdir( CLEANUP => 1 );

_write_stub( File::Spec->catfile( $moving_dir, 'prove' ), "#!/bin/sh\nprintf 'moved\\n' > '$probe'\nexit 0\n" );

# `cover` is called to drop the database and again to report. Neither needs to do
# anything real: this file is about what the gate does when the tree moves, and a
# genuine coverage run would cost minutes and prove nothing extra.
_write_stub( File::Spec->catfile( $moving_dir, 'cover' ), "#!/bin/sh\nexit 0\n" );

my $database = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'cover_db' );

my ( $status, $output ) = _run_gate( $moving_dir, '--database', $database );

is( $status, 5, 'a run whose tree changed underneath it exits 5 instead of reporting a number' );
like(
    $output,
    qr/refusing to report/,
    'the gate says it is refusing to report, rather than emitting a figure nobody should trust'
);
like(
    $output,
    qr/changed while the suite ran/,
    'the refusal names the cause, so the reader does not go hunting through their own code'
);
like(
    $output,
    qr/rerun it on a tree nobody is moving/,
    'the refusal says what to do about it, since the answer is a rerun and not a debugging session'
);
ok(
    -e $probe,
    'the staged change really happened, so this is observing detection and not a stub that quietly did nothing'
);

unlink $probe;

# The complement matters as much as the detection. This check hashes two entire
# directories, so it could easily refuse everything - and a gate that always
# refuses cannot be told apart from a broken one. A suite that leaves the tree
# alone must pass straight through it.
#
# The moving stub cannot be reused here: its whole purpose is to change the tree,
# so running it again would be refused for the right reason while proving nothing
# about the wrong one.
my $quiet_dir = tempdir( CLEANUP => 1 );
_write_stub( File::Spec->catfile( $quiet_dir, 'prove' ), "#!/bin/sh\nexit 0\n" );
_write_stub( File::Spec->catfile( $quiet_dir, 'cover' ), "#!/bin/sh\nexit 0\n" );

my ( $quiet_status, undef ) = _run_gate( $quiet_dir, '--database', $database );

isnt( $quiet_status, 5, 'a run whose tree stayed put is not refused, so the check is not simply always on' );

# Purpose: write an executable stand-in onto the throwaway PATH.
# Input: the path to write, and the script body.
# Output: nothing; dies if the stub cannot be made runnable.
sub _write_stub {
    my ( $path, $body ) = @_;

    open my $handle, '>', $path or die "Unable to write the stub $path: $!";
    print {$handle} $body;
    close $handle or die "Unable to close the stub $path: $!";
    chmod 0755, $path or die "Unable to make the stub $path executable: $!";

    return;
}

# Purpose: run the gate with the stubbed commands ahead of the real ones.
# Input: the stub directory, then the gate's arguments.
# Output: the exit status already shifted, and the combined output.
sub _run_gate {
    my ( $directory, @arguments ) = @_;

    local $ENV{PATH} = $directory . ':' . $ENV{PATH};
    local $ENV{HARNESS_PERL_SWITCHES};
    delete $ENV{HARNESS_PERL_SWITCHES};

    # List-form system through capture_merged: no shell is involved, so no
    # quoting of the gate path is needed. The old qx{} form built the command
    # with quotemeta, which cmd.exe on Windows does not unescape - perl then
    # received the literal doubled-backslash path and CreateProcess refused it.
    my ( $output, $status ) = capture_merged { system $^X, $gate, @arguments };

    return ( $status >> 8, defined $output ? $output : '' );
}

__END__

=head1 NAME

149-coverage-gate-moving-target.t - prove the gate refuses to report a number for
a tree that changed while it was being graded

=head1 PURPOSE

Show that C<script/coverage-gate> fingerprints the code it is grading, notices when
C<t/> or C<lib/> differs after the suite from before it, and discards the run with
an explanation instead of reporting a figure drawn from two different states of the
tree.

=head1 WHY IT EXISTS

A full gate on this project runs for roughly twenty-six minutes and reads C<t/>
throughout. Anything that moves the tree in that window - a branch switch, a
worktree command, a rebase, an editor writing a file - changes what is being
measured without changing anything the run itself can see.

The consequence is worse than a wasted run. A failure produced that way is
indistinguishable from a genuine one: the same red output, the same file names, and
no signal anywhere that the ground moved. The only safe response to "did anything
change under it?" is therefore to throw away the whole twenty-six minutes. That
happened twice in one afternoon before this check existed, and once more while the
check was being written - a worktree was removed under a running gate, and the new
code caught it, which is how the check first proved itself.

The identity is deliberately taken from the graded content rather than from the git
revision. A branch switch that leaves C<t/> and C<lib/> byte-identical has changed
nothing that can affect the number and should not be refused; a change that touches
them is caught whether git was involved at all.

=head1 WHEN TO USE

Run it whenever the gate's run sequence changes, and in particular if the identity
check moves relative to the suite - it has to bracket the suite, since that is the
long window being protected. It needs no special environment and takes about a
second, because the suite it runs is a stand-in.

=head1 HOW TO USE

    prove -lv t/149-coverage-gate-moving-target.t

=head1 WHAT USES IT

The full suite via C<prove -lr t>, the all-metric coverage gate, and the CI workflow
that runs both.

=head1 EXAMPLES

The real window is minutes wide, so racing it would produce a flaky test that proves
nothing. Instead the change is staged at exactly the moment it matters, by giving the
gate a C<prove> that moves the tree while it runs:

    _write_stub( "$moving_dir/prove", "#!/bin/sh\nprintf 'moved\n' > '$probe'\nexit 0\n" );
    my ( $status, $output ) = _run_gate( $moving_dir, '--database', $database );
    is( $status, 5, '...' );

The last assertion is the complement, and matters as much as the detection: with the
tree left alone, the same invocation is B<not> refused.

=cut

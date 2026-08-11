#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Cwd qw(getcwd);
use Fcntl qw(:flock);
use File::Spec;
use File::Temp qw(tempdir);

# The gate refuses to be the second run against one coverage database. That
# refusal is the entire value of the lock, so it has to be observed rather than
# assumed: an unlocked gate and a locked one differ only in what they do when
# somebody else is already there, and nothing else in the suite ever puts
# somebody else there.
#
# This is testable without racing two real gates, which would be both slow and
# flaky. The lock is an ordinary advisory flock on a file at the repository
# root, so this process can hold it directly and then ask the gate to run. The
# gate reaches the lock before it deletes anything or starts a suite, so a
# refused run costs nothing and touches no database.

my $repository = getcwd();
my $gate       = File::Spec->catfile( $repository, 'script', 'coverage-gate' );

plan skip_all => "the coverage gate is not present at $gate" if !-f $gate;

# The staged conflict is over a database of this test's own, never the real
# cover_db. That is not merely tidiness. The gate names its lock after the
# database it intends to own, so a private database gives a private lock, and
# this file cannot be blocked by - or block - a genuine gate running on the same
# host. An earlier version contended for one fixed repository-wide lock, which
# meant the suite could not be run BY the gate: the gate held that lock for the
# whole run and then refused the tests that drive it.
my $database = File::Temp::tempdir( CLEANUP => 1 );
my $scratch  = File::Spec->catdir( $database, 'cover_db' );

# Mirrors _gate_lock_path in the script: a dotfile named after the database and
# sitting beside it, so deleting the database cannot delete its own lock.
my $lock_path = File::Spec->catfile( $database, '.cover_db.lock' );

my $held;
if ( !open $held, '+>>', $lock_path ) {
    plan skip_all => "the lock file $lock_path could not be opened: $!";
}

# Deliberately fatal rather than a skip. Nothing else can hold this lock - the
# directory was created moments ago and its name is known only to this process -
# so a refusal here means the locking itself is broken. Skipping on that would
# turn the one file that tests the lock into zero tests, and report it as green.
flock $held, LOCK_EX | LOCK_NB
    or die "Unable to take a private lock at $lock_path, which nothing else can hold: $!";

plan tests => 9;

# Hold it the way a real gate holds it. Taking the flock is what stops the second
# run, but recording the pid is what makes the refusal useful to a person, and a
# holder that skipped this step would have the test asserting a message no real
# gate would ever produce.
truncate $held, 0;
seek $held, 0, 0;
print {$held} "$$\n";
$held->flush if $held->can('flush');

my ( $refused_output, $refused_status ) = _run_gate( '--database', $scratch, 't/00-load.t' );

is( $refused_status, 4, 'a gate that cannot own the database exits 4 rather than running' );
like(
    $refused_output,
    qr/refusing to run/,
    'the refusal says it is refusing, instead of failing silently or looking like a crash'
);
like(
    $refused_output,
    qr/means nothing/,
    'the refusal explains the consequence it is avoiding, so the reader knows why waiting is better'
);
like(
    $refused_output,
    qr/pid $$\b/,
    'the refusal names the exact process holding the gate, so the operator can find it'
);
ok(
    !-d $scratch,
    'a refused gate deletes nothing: it stops before it can destroy the data the other run is accumulating'
);
unlike(
    $refused_output,
    qr{t/00-load\.t \s* \.+ \s* ok}x,
    'a refused gate never starts the suite, so it costs a host-exclusive slot nothing to be turned away'
);

# Describing the chain must never block. An operator asking what the gate would
# do is not competing for the database, and making --dry-run wait behind a real
# run would make the gate impossible to inspect exactly when inspecting it is
# most useful.
my ( $dry_output, $dry_status ) = _run_gate( '--database', $scratch, '--dry-run' );

is( $dry_status, 0, 'a dry run succeeds while another gate holds the lock' );
unlike( $dry_output, qr/refusing to run/, 'a dry run is not refused, because it competes for nothing' );

# Releasing must actually release. A lock that is never given back turns the
# first gate on a host into the only gate that will ever run there, which fails
# closed but fails permanently.
close $held;

open my $after, '+>>', $lock_path or die "Unable to reopen $lock_path: $!";
ok(
    ( flock $after, LOCK_EX | LOCK_NB ),
    'the lock is released when its holder lets go, so the next gate can run'
);
close $after;

# Purpose: run the gate as a separate process and collect what it said and how
#          it ended, since both are part of the behaviour under test.
# Input: the argument list to pass to the gate.
# Output: the combined output, and the exit status already shifted.
sub _run_gate {
    my @arguments = @_;

    my $output = qx{$^X \Q$gate\E @{[ join ' ', map { quotemeta } @arguments ]} 2>&1};

    return ( defined $output ? $output : '', $? >> 8 );
}

__END__

=head1 NAME

146-coverage-gate-lock.t - prove the coverage gate refuses to be the second run
against one database

=head1 PURPOSE

Prove that a gate which cannot take the shared lock stops before it deletes
anything or starts a suite, and says which process holds it - and that describing
the chain with C<--dry-run> is never blocked by a run in flight.

=head1 WHY IT EXISTS

The coverage database is one shared tree per checkout, and the chain's first act is
C<cover cover_db -delete>. Two gates on a host therefore do not merely queue badly:
each clears the other's accumulated data mid-suite, and both go on to report a
percentage drawn from a suite neither of them ran to completion.

That is worse than a crash. A crash is visible and nobody trusts its output. This
produces a plausible-looking number that cannot be told apart from a real one - and
in a project whose bar is a hundred point zero on all four metrics, a number that
cannot be trusted is indistinguishable from one that has been met.

It was not hypothetical when the lock was written. Two gates were running against
this checkout at the time, one of them started by a round and one by hand.

=head1 WHEN TO USE

Run it whenever C<script/coverage-gate> is touched, and in particular whenever the
order of its startup steps changes - the lock must stay after the dry-run return
and before the database drop. It is part of the ordinary suite and needs no special
environment.

=head1 HOW TO USE

    prove -lv t/146-coverage-gate-lock.t

=head1 WHAT USES IT

The full suite via C<prove -lr t>, the all-metric coverage gate, and the CI
workflow that runs both.

=head1 EXAMPLES

The refusal is observed rather than assumed, and without racing two real gates,
which would be slow and flaky. The lock is an ordinary advisory C<flock>, so this
process holds it the way a real gate does - the flock plus the recorded pid, since
taking the lock is what stops the second run but recording the pid is what makes
the refusal useful to a person:

    flock $held, LOCK_EX | LOCK_NB;
    truncate $held, 0;
    print {$held} "$$\n";

    my ( $output, $status ) = _run_gate( '--database', $scratch, 't/00-load.t' );
    is( $status, 4, '...' );
    ok( !-d $scratch, '...' );

Verified by mutation. Removing the early return while leaving the warning in place
fails exactly the assertions that distinguish saying from doing - the exit code,
that nothing was deleted, and that the suite never started - while the message
assertions still pass. A gate that announces a conflict and proceeds anyway is the
failure being prevented, so the suite has to be able to tell those apart.

=cut

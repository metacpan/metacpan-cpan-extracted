use warnings;
use strict;

use Data::Dumper;
use IPC::Semaphore;
use IPC::SysV qw(IPC_RMID);
use Test::More;

BEGIN {
    use_ok('IPC::Shareable');
};

# Clear stale testing segments left behind by a previously crashed run.
# clean_up_testing() only removes segments this process created or whose creator
# process has exited, so it is safe to run even under a parallel harness -- it
# will not touch a concurrently-running sibling test file's live segments.
IPC::Shareable->clean_up_testing('IPC::Shareable');

# The async_tests pair needs its own reclaim by name: a leftover from a pre-1.18
# suite has a 4-slot semaphore set with no SEM_TESTING marker, so
# clean_up_testing() cannot prove it is ours. Only this suite ever uses the
# 'async_tests' glue, and the creator-alive check leaves a concurrently-running
# sibling suite alone.
_reclaim_stale_async_tests();

IPC::Shareable->testing_set('IPC::Shareable');

# The whole-suite *count* comparison (below, and in t/99-end) is still inherently
# global, so it stays serial-only: skip it under a parallel harness (eg. a
# smoker running with HARNESS_OPTIONS=jN).
my $parallel = defined $ENV{HARNESS_OPTIONS} && $ENV{HARNESS_OPTIONS} =~ /(?:^|:)j[0-9]/;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

print "Starting with $segs_before segments\n";
is $segs_before, $segs_before, "Initial test ok";

# If an async_tests segment still exists here (live sibling suite, or a stale
# one whose creator appears alive), the tie below ATTACHES instead of creating,
# and the end-of-file count check must not expect a new segment.

my $async_existed
    = defined shmget(IPC::Shareable::_key_str_to_int('async_tests'), 0, 0)
    ? 1
    : 0;

tie my %store, 'IPC::Shareable', {key => 'async_tests', create => 1, serializer => 'storable' };

# Measure the baseline AFTER tying and subtract 1 to exclude the async_tests
# segment/semaphore themselves.  This keeps t/99-end.t's comparison correct
# even when a stale async_tests semaphore was orphaned by a previous crashed
# run (segment removed, semaphore not), causing the pre-tie count to be off.

$store{segs} = IPC::Shareable::seg_count() - 1;
$store{sems} = IPC::Shareable::sem_count() - 1;

{
    my $a = tie my $x, 'IPC::Shareable';
    my $b = tie my $y, 'IPC::Shareable', { create => 1, destroy => 1 , serializer => 'storable' };

    is $a->{_key}, 0, "tie with no glue or options is IPC_PRIVATE ok";
    is $b->{_key}, 0, "tie with no glue but with options is IPC_PRIVATE ok";

    $a->remove;
}

IPC::Shareable::_end;

warn "Segs After: " . IPC::Shareable::seg_count() . "\n" if $ENV{PRINT_SEGS};

SKIP: {
    skip "whole-suite IPC count check is serial-only (parallel harness detected)", 1
        if $parallel;
    is IPC::Shareable::seg_count(), $segs_before + ($async_existed ? 0 : 1),
        "No segs left after test suite run ok";
}

done_testing();

# Remove a stale async_tests segment and/or semaphore set left by a previous
# crashed run, whatever its vintage (marked or not). The segment is only
# removed when its creator process has exited -- same ownership rule as
# clean_up_testing(). An async_tests semaphore with no segment is always a
# broken pair (the segment is created first, removed first), so it is removed
# unconditionally.

sub _reclaim_stale_async_tests {
    my $key_int = IPC::Shareable::_key_str_to_int('async_tests');

    my $id = shmget($key_int, 0, 0);

    if (defined $id) {
        my $probe = bless {}, 'IPC::Shareable::SharedMem';
        $probe->id($id);

        my $stat = eval { $probe->stat };
        my $cpid = defined $stat ? $stat->cpid : undef;

        # Creator still alive: a sibling suite run owns it; leave the pair alone

        return if defined $cpid && $cpid > 0 && $cpid != $$ && kill 0, $cpid;

        shmctl($id, IPC_RMID, 0);
    }

    my $sem = IPC::Semaphore->new($key_int, 0, 0);
    $sem->remove if defined $sem;

    return;
}

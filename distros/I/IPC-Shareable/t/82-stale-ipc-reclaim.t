use warnings;
use strict;

use IPC::Semaphore;
use IPC::SysV qw(IPC_CREAT);
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process require_free_sem_sets unique_glue);

use IPC::Shareable;

# A dedicated dist tag, so the clean_up_testing() calls in this file can only
# ever match resources created here -- NOT the suite's own 'IPC::Shareable'
# tagged ones (eg. t/00-base.t's live async_tests baseline pair, whose creator
# process has exited and would otherwise be reclaimed as a stale pair).
my $DIST = 'IPC::Shareable::T82';

IPC::Shareable->testing_set($DIST);

require_free_sem_sets();

# Coverage for clean_up_testing()'s reclamation of stale IPC left by crashed
# test runs. SysV resources persist until explicitly removed or reboot, so a
# smoker host accumulates them run over run; on OpenBSD (kern.seminfo.semmni
# defaults to 10) the stale semaphore sets eventually starve every semget()
# into ENOSPC and every subsequent run FAILs. Three scenarios:
#
#   1. An orphaned testing-tagged semaphore set (segment already gone) is
#      reclaimed -- these were previously invisible: the reclaim scan walked
#      ipcs -m only, so a sem with no segment was never considered.
#   2. An untagged orphan semaphore set is left alone: ownership cannot be
#      proven, and it could belong to any other application on the host.
#   3. A testing-tagged segment+semaphore pair whose creator process has
#      exited (a crashed run's leftovers) is reclaimed whole.

# ---------------------------------------------------------------------------
# 1. Orphaned testing-tagged semaphore set (no segment) is reclaimed
# ---------------------------------------------------------------------------
{
    my $glue    = unique_glue('orphan-marked-sem');
    my $key_int = IPC::Shareable::_key_str_to_int($glue);
    my $target  = IPC::Shareable::_testing_semaphore_key_hash($DIST);

    my $sem = IPC::Semaphore->new($key_int, 5, IPC_CREAT | 0666);
    ok defined $sem, 'marked orphan: created a bare 5-slot semaphore set (no segment)';

    ok $sem->setval(IPC::Shareable::SEM_TESTING, $target),
        'marked orphan: SEM_TESTING marker set';

    my $removed = IPC::Shareable->clean_up_testing($DIST);
    cmp_ok $removed, '>=', 1, 'clean_up_testing() reports the reclaim';

    my $still = IPC::Semaphore->new($key_int, 0, 0);
    ok ! defined $still, 'marked orphan: semaphore set was reclaimed';

    # Safety net if a regression leaves it behind
    $still->remove if defined $still;
}

# ---------------------------------------------------------------------------
# 2. Untagged orphan semaphore set is NOT touched (ownership unprovable)
# ---------------------------------------------------------------------------
{
    my $glue    = unique_glue('orphan-unmarked-sem');
    my $key_int = IPC::Shareable::_key_str_to_int($glue);

    my $sem = IPC::Semaphore->new($key_int, 4, IPC_CREAT | 0666);
    ok defined $sem, 'unmarked orphan: created a bare 4-slot semaphore set (no segment)';

    IPC::Shareable->clean_up_testing($DIST);

    my $still = IPC::Semaphore->new($key_int, 0, 0);
    ok defined $still, 'unmarked orphan: left alone by clean_up_testing()';

    $still->remove if defined $still;
}

# ---------------------------------------------------------------------------
# 3. Testing-tagged pair with a dead creator is reclaimed whole
# ---------------------------------------------------------------------------
{
    my $glue    = unique_glue('stale-marked-pair');
    my $key_int = IPC::Shareable::_key_str_to_int($glue);

    my $pid = fork;
    die "Cannot fork: $!" if ! defined $pid;

    if ($pid == 0) {
        # Child: create a marked pair and exit WITHOUT cleaning up (no destroy
        # attribute), replicating what a crashed run leaves behind

        tie my %h, 'IPC::Shareable', { key => $glue, create => 1 };
        $h{stale} = 1;
        exit 0;
    }

    waitpid($pid, 0);

    ok defined shmget($key_int, 0, 0),
        'stale pair: segment persists after the creator exited';
    ok defined IPC::Semaphore->new($key_int, 0, 0),
        'stale pair: semaphore set persists after the creator exited';

    IPC::Shareable->clean_up_testing($DIST);

    ok ! defined shmget($key_int, 0, 0),
        'stale pair: segment reclaimed by clean_up_testing()';

    my $leftover_sem = IPC::Semaphore->new($key_int, 0, 0);
    ok ! defined $leftover_sem,
        'stale pair: semaphore set reclaimed by clean_up_testing()';

    # Safety net
    $leftover_sem->remove if defined $leftover_sem;
}

IPC::Shareable::_end;

assert_clean_process();

done_testing();

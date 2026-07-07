use warnings;
use strict;

# Cross-process LOCK_SH / LOCK_EX blocking tests.
#
# Each test forks a writer child that:
#   1. acquires LOCK_EX on the shared variable
#   2. writes 'updated' to it
#   3. signals the parent via a pipe that LOCK_EX is held
#   4. sleeps 0.3 s (holding the lock)
#   5. releases LOCK_EX and exits
#
# The parent only attempts LOCK_SH *after* receiving the pipe signal, so the
# semaphore wait-for-writers-zero operation is guaranteed to block until the
# child releases LOCK_EX.  The correct post-write value ('updated') is then
# readable once the shared lock is granted.

use IPC::Shareable qw(:lock);
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;
use Test::SharedFork;
use Time::HiRes qw(time);

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(unique_glue assert_clean require_free_sem_sets);

require_free_sem_sets();

# --- Test 1: LOCK_SH blocks until LOCK_EX released (enforced_write_locking disabled) ---
{
    my ($r, $w);
    pipe($r, $w) or die "Cannot create pipe: $!";

    tie my $sv, 'IPC::Shareable', {
        key              => unique_glue('LFBK1'),
        create           => 1,
        destroy          => 1,
        enforced_write_locking => 0,
        enforced_read_locking  => 0,
        serializer       => 'storable',
    };

    $sv = 'initial';

    my $pid = fork;
    defined $pid or die "Cannot fork: $!";

    if ($pid == 0) {
        # writer child
        close $r;
        my $wt = tied $sv;
        $wt->lock(LOCK_EX);
        $sv = 'updated';
        print $w "ready\n";
        close $w;
        select(undef, undef, undef, 0.3);  # hold lock so parent definitely blocks
        $wt->unlock;
        exit 0;
    }

    # parent (reader)
    close $w;
    <$r>;    # wait until child holds LOCK_EX and has written 'updated'
    close $r;
    my $ready = time();

    my $rt = tied $sv;
    my $t0 = time();
    my $got = $rt->lock(LOCK_SH);  # blocks here until child releases LOCK_EX
    my $t1 = time();
    my $wait = $t1 - $t0;

    # The child holds LOCK_EX for 0.3s after signalling readiness, so the floor
    # on the observed wait is whatever remained of that window when this
    # process finally issued the lock call. On a loaded smoker the parent can
    # be descheduled after the pipe read for longer than the whole window -- a
    # fixed 0.28s floor then fails with waits as low as 0.000s (seen on CPAN
    # testers). The functional assertions above are unaffected.

    my $floor = 0.3 - ($t0 - $ready) - 0.02;
    $floor = 0 if $floor < 0;

    is $got, 1,        "LOCK_SH (enforced_write_locking off): lock() returns 1 after LOCK_EX released";
    is $sv, 'updated', "LOCK_SH (enforced_write_locking off): reads value written by LOCK_EX holder";
    ok(
        $wait >= $floor,
        sprintf("Reader blocked on LOCK_SH (waited %.3fs >= floor %.3fs)", $wait, $floor),
    );
    $rt->unlock;

    waitpid($pid, 0);
}

# --- Test 2: LOCK_SH blocks until LOCK_EX released (enforced_write_locking enabled) ---
{
    my ($r, $w);
    pipe($r, $w) or die "Cannot create pipe: $!";

    tie my $sv, 'IPC::Shareable', {
        key              => unique_glue('LFBK2'),
        create           => 1,
        destroy          => 1,
        enforced_write_locking => 1,
        enforced_read_locking  => 1,
        serializer       => 'storable',
    };

    $sv = 'initial';

    my $pid = fork;
    defined $pid or die "Cannot fork: $!";

    if ($pid == 0) {
        # writer child
        close $r;
        my $wt = tied $sv;
        $wt->lock(LOCK_EX);
        $sv = 'updated';
        print $w "ready\n";
        close $w;
        select(undef, undef, undef, 0.3);
        $wt->unlock;
        exit 0;
    }

    # parent (reader)
    close $w;
    <$r>;
    close $r;

    my $rt = tied $sv;
    my $got = $rt->lock(LOCK_SH);

    is $got, 1,        "LOCK_SH (enforced_write_locking on): lock() returns 1 after LOCK_EX released";
    is $sv, 'updated', "LOCK_SH (enforced_write_locking on): reads value written by LOCK_EX holder";
    $rt->unlock;

    waitpid($pid, 0);
}

# --- Test 3: LOCK_SH|LOCK_NB returns 0 immediately while LOCK_EX is held ---
{
    my ($r, $w);
    pipe($r, $w) or die "Cannot create pipe: $!";

    tie my $sv, 'IPC::Shareable', {
        key        => unique_glue('LFBK3'),
        create     => 1,
        destroy    => 1,
        serializer => 'storable',
    };

    $sv = 'initial';

    my $pid = fork;
    defined $pid or die "Cannot fork: $!";

    if ($pid == 0) {
        # writer child holds LOCK_EX for long enough that the parent's
        # non-blocking attempt definitely races against it
        close $r;
        my $wt = tied $sv;
        $wt->lock(LOCK_EX);
        print $w "ready\n";
        close $w;
        select(undef, undef, undef, 0.5);
        $wt->unlock;
        exit 0;
    }

    # parent
    close $w;
    <$r>;    # writer now holds LOCK_EX
    close $r;

    my $rt = tied $sv;
    my $got = $rt->lock(LOCK_SH | LOCK_NB);

    is $got, 0,         "LOCK_SH|LOCK_NB: returns 0 (would block) while LOCK_EX is held";
    is $rt->{_lock}, 0, "LOCK_SH|LOCK_NB: _lock remains 0 when non-blocking attempt fails";

    waitpid($pid, 0);
}

# --- Test 4: Two readers with LOCK_SH both block until LOCK_EX released ---
{
    my ($r, $w);
    pipe($r, $w) or die "Cannot create pipe: $!";

    tie my $sv, 'IPC::Shareable', {
        key              => unique_glue('LFBK4'),
        create           => 1,
        destroy          => 1,
        enforced_write_locking => 0,
        enforced_read_locking  => 0,
        serializer       => 'storable',
    };

    $sv = 'initial';

    my $writer_pid = fork;
    defined $writer_pid or die "Cannot fork writer: $!";

    if ($writer_pid == 0) {
        close $r;
        my $wt = tied $sv;
        $wt->lock(LOCK_EX);
        $sv = 'updated';
        print $w "ready\n";
        close $w;
        select(undef, undef, undef, 0.3);
        $wt->unlock;
        exit 0;
    }

    close $w;
    <$r>;    # writer now holds LOCK_EX and has written 'updated'
    close $r;

    # Fork two reader children; both block on LOCK_SH until writer releases EX.
    # Multiple concurrent LOCK_SH holders are permitted by the SysV semaphore
    # scheme, so both unblock together once SEM_WRITERS drops to 0.
    my @reader_pids;
    for my $n (1, 2) {
        my $rpid = fork;
        defined $rpid or die "Cannot fork reader $n: $!";
        if ($rpid == 0) {
            my $rt = tied $sv;
            my $got = $rt->lock(LOCK_SH);
            is $got, 1,        "LOCK_SH two readers (reader $n): lock() returns 1 after LOCK_EX released";
            is $sv, 'updated', "LOCK_SH two readers (reader $n): reads value written by LOCK_EX holder";
            $rt->unlock;
            exit 0;
        }
        push @reader_pids, $rpid;
    }

    waitpid($writer_pid, 0);
    waitpid($_, 0) for @reader_pids;
}
# --- Test 5: LOCK_EX blocks until previous LOCK_EX released ---
{
    my ($r, $w);
    pipe($r, $w) or die "Cannot create pipe: $!";

    tie my $sv, 'IPC::Shareable', {
        key        => unique_glue('LFBK5'),
        create     => 1,
        destroy    => 1,
        serializer => 'storable',
    };

    $sv = 'initial';

    my $pid = fork;
    defined $pid or die "Cannot fork: $!";

    if ($pid == 0) {
        # first writer child
        close $r;
        my $wt = tied $sv;
        $wt->lock(LOCK_EX);
        $sv = 'updated';
        print $w "ready\n";
        close $w;
        select(undef, undef, undef, 0.3);  # hold lock so parent definitely blocks
        $wt->unlock;
        exit 0;
    }

    # parent (second writer)
    close $w;
    <$r>;    # wait until child holds LOCK_EX and has written 'updated'
    close $r;
    my $ready = time();

    my $rt = tied $sv;
    my $t0 = time();
    my $got = $rt->lock(LOCK_EX);  # blocks here until child releases LOCK_EX
    my $t1 = time();
    my $wait = $t1 - $t0;

    # Dynamic floor: see the LOCK_SH block in Test 1 for why a fixed 0.28s
    # floor is a race on loaded smokers.

    my $floor = 0.3 - ($t0 - $ready) - 0.02;
    $floor = 0 if $floor < 0;

    is $got, 1,        "LOCK_EX: lock() returns 1 after previous LOCK_EX released";
    is $sv, 'updated', "LOCK_EX: reads value written by previous LOCK_EX holder";
    ok(
        $wait >= $floor,
        sprintf("Writer blocked on LOCK_EX (waited %.3fs >= floor %.3fs)", $wait, $floor),
    );
    $rt->unlock;

    waitpid($pid, 0);
}

# --- Test 6: LOCK_EX|LOCK_NB returns 0 immediately while another LOCK_EX is held ---
{
    my ($r, $w);
    pipe($r, $w) or die "Cannot create pipe: $!";

    tie my $sv, 'IPC::Shareable', {
        key        => unique_glue('LFBK6'),
        create     => 1,
        destroy    => 1,
        serializer => 'storable',
    };

    $sv = 'initial';

    my $pid = fork;
    defined $pid or die "Cannot fork: $!";

    if ($pid == 0) {
        # first writer child holds LOCK_EX for long enough that the parent's
        # non-blocking attempt definitely races against it
        close $r;
        my $wt = tied $sv;
        $wt->lock(LOCK_EX);
        print $w "ready\n";
        close $w;
        select(undef, undef, undef, 0.5);
        $wt->unlock;
        exit 0;
    }

    # parent (second writer)
    close $w;
    <$r>;    # writer now holds LOCK_EX
    close $r;

    my $rt = tied $sv;
    my $got = $rt->lock(LOCK_EX | LOCK_NB);

    is $got, 0,         "LOCK_EX|LOCK_NB: returns 0 (would block) while another LOCK_EX is held";
    is $rt->{_lock}, 0, "LOCK_EX|LOCK_NB: _lock remains 0 when non-blocking attempt fails";

    waitpid($pid, 0);
}

IPC::Shareable::_end;

assert_clean(map { unique_glue($_) } qw(LFBK1 LFBK2 LFBK3 LFBK4 LFBK5 LFBK6));

done_testing;

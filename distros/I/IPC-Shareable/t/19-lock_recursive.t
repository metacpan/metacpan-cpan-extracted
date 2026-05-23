use warnings;
use strict;

use IPC::Shareable qw(:lock);
use Test::More;
use Test::SharedFork;
use Time::HiRes qw(time);

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

# --- Test 1: LOCK_EX on root holds child semaphore (LOCK_NB returns 0) ---
{
    my $root = tie my %h, 'IPC::Shareable', {
        key        => 'LR191',
        create     => 1,
        destroy    => 1,
        serializer => 'json',
    };

    $h{a} = { x => 1 };
    my $child = tied(%{ $h{a} });

    pipe(my $r, my $w) or die "pipe: $!";

    my $pid = fork;
    defined $pid or die "fork: $!";

    if ($pid == 0) {
        close $w;
        <$r>;   # wait for parent to hold LOCK_EX
        close $r;
        my $got = $child->lock(LOCK_EX | LOCK_NB);
        is $got, 0, "LOCK_EX on root: child LOCK_EX|LOCK_NB returns 0 while parent holds lock";
        exit 0;
    }

    close $r;
    $root->lock(LOCK_EX);
    print $w "ready\n"; close $w;
    select(undef, undef, undef, 0.3);
    $root->unlock;

    waitpid($pid, 0);

    IPC::Shareable->clean_up_all;
}

# --- Test 2: child semaphore released after parent unlock ---
{
    my $root = tie my %h, 'IPC::Shareable', {
        key        => 'LR192',
        create     => 1,
        destroy    => 1,
        serializer => 'json',
    };

    $h{a} = { x => 1 };
    my $child = tied(%{ $h{a} });

    pipe(my $r,  my $w)  or die "pipe1: $!";
    pipe(my $r2, my $w2) or die "pipe2: $!";

    my $pid = fork;
    defined $pid or die "fork: $!";

    if ($pid == 0) {
        close $w;   # child doesn't write to pipe1
        close $r2;  # child doesn't read from pipe2
        <$r>;       # wait for parent to unlock
        close $r;
        my $got = $child->lock(LOCK_EX | LOCK_NB);
        is $got, 1, "child LOCK_EX|LOCK_NB succeeds after parent unlock";
        $child->unlock if $got;
        print $w2 "done\n"; close $w2;
        exit 0;
    }

    close $r;   # parent doesn't read from pipe1
    close $w2;  # parent doesn't write to pipe2
    $root->lock(LOCK_EX);
    select(undef, undef, undef, 0.1);
    $root->unlock;
    print $w "go\n"; close $w;
    <$r2>; close $r2;   # wait for child assertion

    waitpid($pid, 0);

    IPC::Shareable->clean_up_all;
}

# --- Test 3: LOCK_SH on root holds LOCK_SH on child (blocks writers, not readers) ---
{
    my $root = tie my %h, 'IPC::Shareable', {
        key        => 'LR193',
        create     => 1,
        destroy    => 1,
        serializer => 'json',
    };

    $h{a} = { x => 1 };
    my $child = tied(%{ $h{a} });

    pipe(my $r, my $w) or die "pipe: $!";

    my $pid = fork;
    defined $pid or die "fork: $!";

    if ($pid == 0) {
        close $w;
        <$r>;
        close $r;

        # LOCK_SH should succeed concurrently with parent's LOCK_SH
        my $sh_got = $child->lock(LOCK_SH | LOCK_NB);
        is $sh_got, 1, "LOCK_SH on root: child LOCK_SH|LOCK_NB succeeds (readers share)";
        $child->unlock if $sh_got;

        # LOCK_EX must be blocked by parent's LOCK_SH
        my $ex_got = $child->lock(LOCK_EX | LOCK_NB);
        is $ex_got, 0, "LOCK_SH on root: child LOCK_EX|LOCK_NB blocked while parent holds LOCK_SH";

        exit 0;
    }

    close $r;
    $root->lock(LOCK_SH);
    print $w "ready\n"; close $w;
    select(undef, undef, undef, 0.3);
    $root->unlock;

    waitpid($pid, 0);

    IPC::Shareable->clean_up_all;
}

# --- Test 4: child _was_changed flushed to shared memory on parent unlock ---
{
    my $root = tie my %h, 'IPC::Shareable', {
        key        => 'LR194',
        create     => 1,
        destroy    => 1,
        serializer => 'json',
    };

    $h{a} = { x => 1 };
    my $child = tied(%{ $h{a} });

    $root->lock(LOCK_EX);

    $h{a}{y} = 99;   # STORE on child under parent's lock

    is $child->{_was_changed}, 1, "_was_changed set on child knot after STORE under parent LOCK_EX";

    $root->unlock;

    is $child->{_was_changed}, 0, "_was_changed cleared on child after parent unlock";
    is $h{a}{y}, 99, "child write-back visible via FETCH after parent unlock";

    IPC::Shareable->clean_up_all;
}

# --- Test 5: 3-level deep nesting — all semaphores held ---
{
    my $root = tie my %h, 'IPC::Shareable', {
        key        => 'LR195',
        create     => 1,
        destroy    => 1,
        serializer => 'json',
    };

    $h{a} = { b => { c => 1 } };
    my $a_knot = tied(%{ $h{a} });
    my $b_knot = tied(%{ $h{a}{b} });

    pipe(my $r, my $w) or die "pipe: $!";

    my $pid = fork;
    defined $pid or die "fork: $!";

    if ($pid == 0) {
        close $w;
        <$r>;
        close $r;

        my $a_got = $a_knot->lock(LOCK_EX | LOCK_NB);
        is $a_got, 0, "3-level: level-1 child LOCK_EX|LOCK_NB blocked";

        my $b_got = $b_knot->lock(LOCK_EX | LOCK_NB);
        is $b_got, 0, "3-level: level-2 grandchild LOCK_EX|LOCK_NB blocked";

        exit 0;
    }

    close $r;
    $root->lock(LOCK_EX);
    print $w "ready\n"; close $w;
    select(undef, undef, undef, 0.3);
    $root->unlock;

    waitpid($pid, 0);

    IPC::Shareable->clean_up_all;
}

# --- Test 6: LOCK_NB rollback — grandchild pre-locked, root LOCK_NB returns 0 ---
{
    my $root = tie my %h, 'IPC::Shareable', {
        key        => 'LR196',
        create     => 1,
        destroy    => 1,
        serializer => 'json',
    };

    $h{a} = { b => { c => 1 } };
    my $a_knot = tied(%{ $h{a} });
    my $b_knot = tied(%{ $h{a}{b} });

    pipe(my $r, my $w) or die "pipe: $!";

    my $pid = fork;
    defined $pid or die "fork: $!";

    if ($pid == 0) {
        # child holds LOCK_EX on grandchild to block the parent's NB attempt
        close $r;
        $b_knot->lock(LOCK_EX);
        print $w "locked\n"; close $w;
        select(undef, undef, undef, 0.5);
        $b_knot->unlock;
        exit 0;
    }

    close $w;
    <$r>;   # grandchild is now locked by child process
    close $r;

    my $got = $root->lock(LOCK_EX | LOCK_NB);

    is $got,               0, "LOCK_NB rollback: root lock returns 0 when grandchild is locked";
    is $root->{_lock},     0, "LOCK_NB rollback: root _lock reset to 0";
    is $a_knot->{_lock},   0, "LOCK_NB rollback: level-1 child _lock reset to 0";

    # Verify root's semaphore was also released (NB attempt should succeed now for root alone)
    my $root_nb = $root->lock(LOCK_EX | LOCK_NB);
    is $root_nb, 0, "LOCK_NB rollback: root semaphore released (still blocked by held grandchild)";

    waitpid($pid, 0);

    # After child releases, full lock should now work
    my $final = $root->lock(LOCK_EX | LOCK_NB);
    is $final, 1, "LOCK_NB rollback: root lock succeeds once grandchild is free";
    $root->unlock if $final;

    IPC::Shareable->clean_up_all;
}

# --- Test 7: _locked_children cleared after unlock ---
{
    my $root = tie my %h, 'IPC::Shareable', {
        key        => 'LR197',
        create     => 1,
        destroy    => 1,
        serializer => 'json',
    };

    $h{a} = { x => 1 };

    $root->lock(LOCK_EX);
    is scalar(@{ $root->{_locked_children} // [] }), 1,
        "_locked_children populated during LOCK_EX";
    $root->unlock;
    is scalar(@{ $root->{_locked_children} // [] }), 0,
        "_locked_children cleared after unlock";

    IPC::Shareable->clean_up_all;
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing;

use warnings;
use strict;

use IPC::Shareable qw(:lock SEM_READERS SEM_WRITERS);
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

# --- LOCK_SH blocks writes from other knots (enforced_write_locking) ---
{
    my $k1 = tie my %h1, 'IPC::Shareable', {
        key              => 'SLCK1',
        create           => 1,
        destroy          => 1,
        enforced_write_locking => 1,
        enforced_read_locking  => 1,
            serializer => 'storable',
    };
    my $k2 = tie my %h2, 'IPC::Shareable', {
        key              => 'SLCK1',
        enforced_write_locking => 1,
        enforced_read_locking  => 1,
            serializer => 'storable',
    };

    $h1{a} = 10;
    is $h1{a}, 10, "LOCK_SH enforcement - initial value set ok";

    # k1 acquires a shared read lock
    $k1->lock(LOCK_SH);
    is $k1->sem->getval(SEM_READERS), 1, "LOCK_SH enforcement - reader count is 1 after LOCK_SH";
    is $k1->sem->getval(SEM_WRITERS), 0, "LOCK_SH enforcement - write lock is 0 after LOCK_SH";

    # k2 attempts a write while k1 holds LOCK_SH -- must be blocked
    my $warned = 0;
    {
        local $SIG{__WARN__} = sub {
            my $w = shift;
            like $w, qr/active readers/, "LOCK_SH enforcement - blocked write warns 'active readers'";
            like $w, qr/${\$k2->uuid}/, "LOCK_SH enforcement - warning contains k2 UUID";
            $warned++;
        };
        my $result = $h2{a} = 99;
    }
    is $warned, 1, "LOCK_SH enforcement - exactly one warning emitted";
    is $h1{a}, 10, "LOCK_SH enforcement - k2 write blocked while k1 holds LOCK_SH";

    $k1->unlock;
    is $k1->sem->getval(SEM_READERS), 0, "LOCK_SH enforcement - reader count is 0 after unlock";

    # After k1 releases LOCK_SH, k2 can write freely
    $h2{a} = 99;
    is $h2{a}, 99, "LOCK_SH enforcement - k2 write succeeds after k1 releases LOCK_SH";
}

# --- LOCK_SH holder itself cannot write (must upgrade to LOCK_EX) ---
{
    my $k1 = tie my %h1, 'IPC::Shareable', {
        key              => 'SLCK2',
        create           => 1,
        destroy          => 1,
        enforced_write_locking => 1,
        enforced_read_locking  => 1,
            serializer => 'storable',
    };

    $h1{a} = 10;
    is $h1{a}, 10, "LOCK_SH self-write - initial value set ok";

    $k1->lock(LOCK_SH);

    # k1 holds LOCK_SH and tries to write itself -- must be blocked
    my $warned = 0;
    {
        local $SIG{__WARN__} = sub {
            my $w = shift;
            like $w, qr/active readers/, "LOCK_SH self-write - blocked write warns 'active readers'";
            like $w, qr/${\$k1->uuid}/, "LOCK_SH self-write - warning contains k1 UUID";
            $warned++;
        };
        $h1{a} = 99;
    }
    is $warned, 1, "LOCK_SH self-write - exactly one warning emitted";
    is $h1{a}, 10, "LOCK_SH self-write - write blocked while holding own LOCK_SH";

    $k1->unlock;

    # After upgrading to LOCK_EX, write succeeds
    $k1->lock(LOCK_EX);
    $h1{a} = 99;
    $k1->unlock;
    is $h1{a}, 99, "LOCK_SH self-write - write succeeds after upgrading to LOCK_EX";
}

# --- violated_write_lock_warn fires with 'active readers' message ---
{
    my $k1 = tie my %h1, 'IPC::Shareable', {
        key              => 'SLCK3',
        create           => 1,
        destroy          => 1,
        enforced_write_locking => 1,
        enforced_read_locking  => 1,
            serializer => 'storable',
    };
    my $k2 = tie my %h2, 'IPC::Shareable', {
        key                => 'SLCK3',
        enforced_write_locking => 1,
        enforced_read_locking  => 1,
        violated_write_lock_warn => 1,
            serializer => 'storable',
    };

    $h1{a} = 10;

    $k1->lock(LOCK_SH);

    my $warned = 0;
    local $SIG{__WARN__} = sub {
        my $w = shift;
        my $uuid   = $k2->uuid;
        my $seg_id = $k2->seg->id;

        like $w, qr/active readers/, "violated_write_lock_warn - message mentions 'active readers'";
        like $w, qr/$uuid/,          "violated_write_lock_warn - message contains UUID";
        like $w, qr/$seg_id/,        "violated_write_lock_warn - message contains segment ID";
        $warned++;
    };

    $h2{a} = 99;

    is $warned, 1, "violated_write_lock_warn - warning fired exactly once";

    $k1->unlock;

    # After unlock warning should not fire again
    {
        local $SIG{__WARN__} = sub { fail "violated_write_lock_warn - unexpected warning after unlock: $_[0]" };
        $h2{a} = 99;
    }
    is $h2{a}, 99, "violated_write_lock_warn - write succeeds after readers gone";
}

# --- LOCK_EX blocking still works (regression) ---
{
    my $k1 = tie my %h1, 'IPC::Shareable', {
        key              => 'SLCK4',
        create           => 1,
        destroy          => 1,
        enforced_write_locking => 1,
        enforced_read_locking  => 1,
            serializer => 'storable',
    };
    my $k2 = tie my %h2, 'IPC::Shareable', {
        key              => 'SLCK4',
        enforced_write_locking => 1,
        enforced_read_locking  => 1,
            serializer => 'storable',
    };

    $h1{a} = 10;

    $k1->lock(LOCK_EX);

    my $warned = 0;
    {
        local $SIG{__WARN__} = sub {
            my $w = shift;
            like $w, qr/exclusively locked/, "LOCK_EX regression - blocked write warns 'exclusively locked'";
            like $w, qr/${\$k2->uuid}/, "LOCK_EX regression - warning contains k2 UUID";
            $warned++;
        };
        $h2{a} = 99;
    }
    is $warned, 1, "LOCK_EX regression - exactly one warning emitted";
    is $h1{a}, 10, "LOCK_EX regression - k2 write blocked while k1 holds LOCK_EX";

    $k1->unlock;

    $h2{a} = 99;
    is $h2{a}, 99, "LOCK_EX regression - k2 write succeeds after k1 unlocks";
}

# --- Both write-locking flags disabled: write succeeds silently while
#     another knot holds LOCK_EX (no warning, no block) ---
{
    my $k1 = tie my %h1, 'IPC::Shareable', {
        key                       => 'SLCK5',
        create                    => 1,
        destroy                   => 1,
        enforced_write_locking    => 0,
        violated_write_lock_warn  => 0,
        enforced_read_locking     => 0,
        violated_read_lock_warn   => 0,
        serializer                => 'storable',
    };
    my $k2 = tie my %h2, 'IPC::Shareable', {
        key                       => 'SLCK5',
        enforced_write_locking    => 0,
        violated_write_lock_warn  => 0,
        enforced_read_locking     => 0,
        violated_read_lock_warn   => 0,
        serializer                => 'storable',
    };

    $h1{a} = 10;
    $k1->lock(LOCK_EX);

    {
        local $SIG{__WARN__} = sub { fail "EW=0 VW=0: unexpected warning: $_[0]" };
        $h2{a} = 99;
    }
    pass "EW=0 VW=0: no warning when both write-locking flags are disabled";
    is $h2{a}, 99, "EW=0 VW=0: write succeeds while another knot holds LOCK_EX";

    $k1->unlock;
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing;

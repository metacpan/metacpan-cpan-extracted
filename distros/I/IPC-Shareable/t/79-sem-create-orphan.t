use warnings;
use strict;

use IPC::SysV qw(IPC_RMID);
use IPC::Semaphore;
use Errno qw(ENOSPC);
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');

# Coverage for the _tie() fix: when the shared memory segment is created but the
# semaphore set cannot be (eg. ENOSPC once the host's semaphore limit is hit --
# as on OpenBSD, where kern.seminfo.semmni defaults to 10), the just-created
# segment must be removed before croaking rather than orphaned. The removal is
# gated on ownership: a pure attacher (create => 0) must NEVER remove a segment
# that another process owns.
#
# IPC::Semaphore->new is forced to fail with a block-scoped typeglob override --
# the same approach t/60-exceptions.t uses, because Mock::Sub 1.08 mishandles
# return_value => undef, so a bare `return` (failure in any context) is used.
#
# Before the fix, t/60-exceptions.t had to clean up the orphaned segment by hand
# ("created before IPC::Semaphore->new failed, so it is not in any register").
# These tests assert that orphan no longer happens.

# ---------------------------------------------------------------------------
# Creator: a failed semaphore create removes the just-created segment (no orphan).
# ---------------------------------------------------------------------------
{
    my $glue    = unique_glue('sem-fail-creator');
    my $key_int = IPC::Shareable::_key_str_to_int($glue);

    my $before = scalar keys %{ IPC::Shareable->global_register };

    {
        no warnings 'redefine';
        local *IPC::Semaphore::new = sub { return };

        my $ok = eval {
            tie my $s, 'IPC::Shareable', { key => $glue, create => 1, destroy => 1 };
            1;
        };
        ok ! $ok, 'creator: tie croaks when the semaphore set cannot be created';
        like $@, qr/Could not create semaphore set/, '...with the expected message';
    }

    my $leaked = shmget($key_int, 0, 0);
    ok ! defined $leaked,
        'creator: the just-created segment was removed, not orphaned';

    is scalar keys %{ IPC::Shareable->global_register }, $before,
        'creator: nothing left dangling in the global register';

    # Safety net: if a regression reintroduces the leak, don't let it escape this
    # test and pollute the host's IPC table.
    shmctl($leaked, IPC_RMID, 0) if defined $leaked;
}

# ---------------------------------------------------------------------------
# The croak preserves the ORIGINAL errno across the cleanup removal, so the
# message still names the real cause (eg. ENOSPC) rather than the result of the
# internal shmctl used to remove the orphaned segment.
# ---------------------------------------------------------------------------
{
    my $glue   = unique_glue('sem-fail-errno');
    my $enospc = do { local $! = ENOSPC; "$!" };

    {
        no warnings 'redefine';
        local *IPC::Semaphore::new = sub { $! = ENOSPC; return };

        eval {
            tie my $s, 'IPC::Shareable', { key => $glue, create => 1, destroy => 1 };
            1;
        };
    }

    like $@, qr/Could not create semaphore set: \Q$enospc\E/,
        'croak preserves the original errno across the orphan-cleanup removal';
}

# ---------------------------------------------------------------------------
# Lock-acquire failure: if the semaphore op fails right after the segment and
# its semaphore were created (before the knot is registered), both are torn
# down before croaking rather than orphaned.
# ---------------------------------------------------------------------------
{
    my $glue    = unique_glue('op-fail-creator');
    my $key_int = IPC::Shareable::_key_str_to_int($glue);

    {
        no warnings 'redefine';
        local *IPC::Semaphore::op = sub { 0 };   # Fail every semop

        my $ok = eval {
            tie my $s, 'IPC::Shareable', { key => $glue, create => 1, destroy => 1 };
            1;
        };
        ok ! $ok, 'lock-acquire failure: tie croaks';
        like $@, qr/Could not obtain semaphore set lock/, '...with the expected message';
    }

    my $leaked_seg = shmget($key_int, 0, 0);
    ok ! defined $leaked_seg,
        'lock-acquire failure: the just-created segment was removed, not orphaned';

    my $leaked_sem = IPC::Semaphore->new($key_int, 0, 0);
    ok ! defined $leaked_sem,
        'lock-acquire failure: the just-created semaphore set was removed too';

    # Safety net
    shmctl($leaked_seg, IPC_RMID, 0) if defined $leaked_seg;
    $leaked_sem->remove if defined $leaked_sem;
}

# ---------------------------------------------------------------------------
# Attacher: a failed semaphore create must NOT remove a segment we didn't create.
# (Guards against an over-aggressive fix that removes the segment unconditionally.)
# ---------------------------------------------------------------------------
{
    my $glue    = unique_glue('sem-fail-attacher');
    my $key_int = IPC::Shareable::_key_str_to_int($glue);

    tie my %owner, 'IPC::Shareable', { key => $glue, create => 1, destroy => 1 };
    %owner = (alive => 1);

    ok defined shmget($key_int, 0, 0), 'attacher: owner segment exists to begin with';

    {
        no warnings 'redefine';
        local *IPC::Semaphore::new = sub { return };

        my $ok = eval {
            tie my %a, 'IPC::Shareable', { key => $glue, create => 0 };
            1;
        };
        ok ! $ok, 'attacher: tie croaks when the semaphore set cannot be created';
        like $@, qr/Could not create semaphore set/, '...with the expected message';
    }

    ok defined shmget($key_int, 0, 0),
        "attacher: the owner's segment was NOT removed by the failed attach";
    is $owner{alive}, 1, "attacher: the owner's data is intact";

    IPC::Shareable::clean_up_all;
}

# ---------------------------------------------------------------------------
# Regression: the success path is unaffected -- the new branch only runs on a
# semaphore-create failure. A normal tie, a ref fan-out, and cleanup all work.
# ---------------------------------------------------------------------------
{
    my $glue    = unique_glue('sem-ok-scalar');
    my $key_int = IPC::Shareable::_key_str_to_int($glue);

    {
        tie my $s, 'IPC::Shareable', { key => $glue, create => 1, destroy => 1 };
        $s = 'hello';
        is $s, 'hello', 'success path: plain scalar round-trips';
        ok defined shmget($key_int, 0, 0), 'success path: segment is live while tied';
    }

    IPC::Shareable::clean_up_all;
    ok ! defined shmget($key_int, 0, 0), 'success path: segment removed on cleanup';
}
{
    tie my $s, 'IPC::Shareable',
        { key => unique_glue('sem-ok-ref'), create => 1, destroy => 1, size => 4096 };
    $s = { a => 1, b => [2, 3] };
    is $s->{a},    1, 'success path: ref fan-out child readable';
    is $s->{b}[1], 3, 'success path: nested child readable';

    IPC::Shareable::clean_up_all;
}

IPC::Shareable::_end;

assert_clean_process();

done_testing();

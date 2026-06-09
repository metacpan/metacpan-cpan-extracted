package IPCShareableTest;

use warnings;
use strict;

use Carp qw(croak);
use Exporter qw(import);
use Test::More;

use IPC::Shareable;
use IPC::Semaphore;

# Below this many SysV semaphore *sets* (SEMMNI), a test that creates many tied
# variables must release them as it goes rather than let them accumulate. Chosen
# to catch tiny hosts (OpenBSD defaults to 10) while leaving roomy ones alone
# (macOS ~87, Linux ~32000).
use constant LOW_SEM_SETS => 32;

our @EXPORT_OK = qw(
    assert_clean assert_clean_process barrier_new barrier_release barrier_wait
    live_seg_count low_sem_resources relieve_ipc_pressure sem_set_limit
    tree_seg_count unique_glue
);

# A token that is unique to this process and stable across fork() (it is
# computed once, at load time, before any test forks). Embedding it in every
# glue string gives each test run its own System V IPC keyspace, so concurrent
# runs on the same host -- eg. a CPAN smoker testing many perls against the
# same release at once -- can no longer collide on the same shared memory
# segment or semaphore set. See evaluation.md for the failure analysis.

our $TOKEN = sprintf '%d-%d', $$, int(rand(1_000_000));

# Assert that every shared memory segment AND semaphore set belonging to the
# given run-scoped glue(s) has been cleaned up. Unlike the old global
# seg_count()/sem_count() comparison, this only inspects resources keyed to
# this run, so it is immune to unrelated IPC activity elsewhere on the host.

sub assert_clean {
    my (@glues) = @_;

    if (! @glues) {
        croak "assert_clean() requires at least one glue string";
    }

    my (@seg_leaks, @sem_leaks);

    for my $glue (@glues) {
        push @seg_leaks, $glue if tree_seg_count($glue) > 0;
        push @sem_leaks, $glue if _sem_exists($glue);
    }

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    is scalar(@seg_leaks), 0, "all of this run's shm segments cleaned up ok"
        or diag "leaked shm segments for glue(s): @seg_leaks";

    is scalar(@sem_leaks), 0, "all of this run's semaphore sets cleaned up ok"
        or diag "leaked semaphore sets for glue(s): @sem_leaks";
}

# Process-scoped end-of-test cleanup assertion. Verifies that THIS process has
# released every IPC::Shareable segment it created, via the module's own global
# register. Immune to IPC activity from other processes (other smokers, or
# parallel `prove -j` siblings), unlike the old global seg_count()/sem_count()
# before/after comparison. One assertion: semaphore sets are created and
# removed in lockstep with their segment, so an empty register implies none
# leaked. NB: only tracks resources created through the normal tie/new path; a
# test that pokes IPC::Shareable::SharedMem (or raw shm) directly should scope
# its own check to the keys it used instead.

sub assert_clean_process {
    my ($label) = @_;

    $label = "this process cleaned up all its IPC::Shareable segments"
        if ! defined $label;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    is live_seg_count(), 0, $label;
}

# Lost-wakeup-safe fork synchronisation, replacing the old SIGALRM/sleep
# handshake where a signal delivered between the "unless $awake" test and
# sleep() was lost and the sleeper blocked forever. A barrier is a single-use
# one-way gate built on a pipe: the waiter blocks in readline() until the peer
# writes a token, so the wakeup arrives as data (with EOF as a backstop) and
# cannot be missed. Create one barrier per synchronisation point BEFORE fork(),
# so both processes inherit its pipe ends. Same idiom as t/38-lsync.t.

sub barrier_new {
    pipe(my $reader, my $writer)
        or croak "barrier_new() could not create pipe: $!";

    return { reader => $reader, writer => $writer };
}

# Release the peer blocked in barrier_wait() on the same barrier. This side
# only signals, so it drops the read end, then writes a token and closes the
# write end (which both delivers the token and yields EOF).

sub barrier_release {
    my ($barrier) = @_;

    if (! defined $barrier) {
        croak "barrier_release() requires a \$barrier param";
    }

    close $barrier->{reader};
    print { $barrier->{writer} } "go\n";
    close $barrier->{writer};
}

# Block until the peer calls barrier_release() on the same barrier. This side
# only waits, so it drops the write end first (otherwise it would hold the pipe
# open and never see EOF), then reads until the peer signals.

sub barrier_wait {
    my ($barrier) = @_;

    if (! defined $barrier) {
        croak "barrier_wait() requires a \$barrier param";
    }

    close $barrier->{writer};
    readline $barrier->{reader};
    close $barrier->{reader};
}

# Count of IPC::Shareable segments currently live and owned by THIS process
# (a tied structure's root plus its nested-reference children), via the
# module's own global register. Process-scoped, so it is immune to unrelated
# IPC activity from other processes -- and unlike tree_seg_count() it works for
# every serializer, including the binary 'storable' format whose child links
# shm_segments() cannot parse back out of segment content.

sub live_seg_count {
    return scalar keys %{ IPC::Shareable->global_register };
}

my $_low_sem_cache;

# True when the host has a small SysV semaphore-set budget (see LOW_SEM_SETS),
# such that a test that creates many tied variables without releasing them
# between steps would exhaust it. Each tie consumes one semaphore set, and on
# OpenBSD the default kern.seminfo.semmni is only 10. An undeterminable limit is
# treated as NOT constrained, so behaviour changes only on platforms we can
# positively identify as small. Cached: the underlying probe runs once.

sub low_sem_resources {
    return $_low_sem_cache if defined $_low_sem_cache;

    my $limit = sem_set_limit();
    $_low_sem_cache = (defined $limit && $limit < LOW_SEM_SETS) ? 1 : 0;

    return $_low_sem_cache;
}

# Release every IPC::Shareable segment this process currently holds, but ONLY on
# hosts with a small semaphore-set budget (see low_sem_resources()). A test that
# creates many tied variables calls this between independent steps to stay under
# the limit. On roomy platforms it is a no-op, so the test's behaviour there is
# unchanged.

sub relieve_ipc_pressure {
    IPC::Shareable::clean_up_all if low_sem_resources();
}

# Return the system-wide limit on SysV semaphore sets (SEMMNI) for the current
# platform, or undef if it cannot be determined. Each IPC::Shareable tie consumes
# one set, so this bounds how many live ties a process may hold at once.

sub sem_set_limit {
    # Reuse the module's own cross-platform probe rather than re-deriving the
    # per-OS sysctl names here: sysv_info() reads kern.sysv (macOS), kern.ipc
    # (FreeBSD), kern.seminfo (OpenBSD), and /proc (Linux). Call it as a class
    # method (it shift()s its invocant) and trap its die-on-missing-sysctl.
    my $info = eval { IPC::Shareable->sysv_info };
    return undef if ! $info;

    my $semmni = $info->{semmni};

    return defined $semmni && $semmni =~ /^\d+$/ ? $semmni : undef;
}

# Number of live IPC::Shareable segments in this glue's segment tree (the root
# plus any nested-reference child segments), as seen in the OS at the key
# level. Used by assert_clean() to confirm real cleanup. Note: only the JSON
# serializer records child links in a form shm_segments() can follow, so for
# measuring a live storable structure's size use live_seg_count() instead.

sub tree_seg_count {
    my ($glue) = @_;

    if (! defined $glue) {
        croak "tree_seg_count() requires a \$glue param";
    }

    my $segs = IPC::Shareable::shm_segments($glue);

    return scalar keys %$segs;
}

# Turn a human-readable base name into a glue string that is unique to this
# process. Deterministic within a process: unique_glue('foo') always returns
# the same string, in both the parent and any forked child, so both sides of a
# fork tie to the same key.

sub unique_glue {
    my ($base) = @_;

    if (! defined $base) {
        croak "unique_glue() requires a \$base param";
    }

    return "${base}-${TOKEN}";
}

sub _sem_exists {
    my ($glue) = @_;

    if (! defined $glue) {
        croak "_sem_exists() requires a \$glue param";
    }

    my $key = IPC::Shareable::_key_str_to_int($glue);

    # Attach-only (nsems => 0, flags => 0): returns an object if a semaphore
    # set already exists for this key, undef otherwise. This is the same probe
    # IPC::Shareable itself uses when removing a set.

    my $sem = IPC::Semaphore->new($key, 0, 0);

    return defined $sem ? 1 : 0;
}

1;

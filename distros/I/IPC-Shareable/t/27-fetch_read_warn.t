use warnings;
use strict;

use IPC::Shareable qw(:lock);
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;
use Test::SharedFork;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

# --- Unlocked FETCH warns when another knot holds LOCK_EX ---
{
    my $k1 = tie my %h1, 'IPC::Shareable', {
        key              => 'RW01',
        create           => 1,
        destroy          => 1,
        enforced_read_locking => 1,
        violated_read_lock_warn => 1,
        serializer       => 'storable',
    };
    my $k2 = tie my %h2, 'IPC::Shareable', {
        key              => 'RW01',
        enforced_read_locking => 1,
        violated_read_lock_warn => 1,
        serializer       => 'storable',
    };

    $h1{a} = 10;

    pipe(my $r, my $w) or die "pipe: $!";

    my $pid = fork;
    defined $pid or die "fork: $!";

    if ($pid == 0) {
        close $r;
        $k1->lock(LOCK_EX);
        print $w "locked\n";
        close $w;
        select(undef, undef, undef, 0.3);
        $k1->unlock;
        exit 0;
    }

    close $w;

    # Block until child signals it has acquired LOCK_EX
    my $line = <$r>;
    close $r;

    my $warned = 0;
    {
        local $SIG{__WARN__} = sub {
            my $w = shift;
            like $w, qr/exclusively locked/, "read warn - message mentions 'exclusively locked'";
            like $w, qr/${\$k2->uuid}/,      "read warn - message contains k2 UUID";
            like $w, qr/${\$k2->seg->id}/,   "read warn - message contains segment ID";
            like $w, qr/stale/,              "read warn - message mentions stale data risk";
            like $w, qr/LOCK_SH/,            "read warn - message suggests LOCK_SH";
            $warned++;
        };
        my $val = $h2{a};
    }

    is $warned, 1, "read warn - exactly one warning emitted";

    waitpid($pid, 0);

    # After child releases LOCK_EX, unlocked read must not warn
    {
        local $SIG{__WARN__} = sub { fail "read warn - unexpected warning after unlock: $_[0]" };
        my $val = $h2{a};
    }
    pass "read warn - no warning after LOCK_EX released";
}

# --- No warning when enforced_read_locking is disabled ---
{
    my $k1 = tie my %h1, 'IPC::Shareable', {
        key              => 'RW02',
        create           => 1,
        destroy          => 1,
        enforced_read_locking => 0,
        violated_read_lock_warn => 1,
        serializer       => 'storable',
    };
    my $k2 = tie my %h2, 'IPC::Shareable', {
        key              => 'RW02',
        enforced_read_locking => 0,
        violated_read_lock_warn => 1,
        serializer       => 'storable',
    };

    $h1{a} = 10;
    $k1->lock(LOCK_EX);

    {
        local $SIG{__WARN__} = sub { fail "no-enforced - unexpected warning: $_[0]" };
        my $val = $h2{a};
    }
    pass "no warning when enforced_read_locking is disabled";

    $k1->unlock;
}

# --- No warning when violated_read_lock_warn is disabled ---
{
    my $k1 = tie my %h1, 'IPC::Shareable', {
        key              => 'RW03',
        create           => 1,
        destroy          => 1,
        enforced_read_locking => 1,
        violated_read_lock_warn => 0,
        serializer       => 'storable',
    };
    my $k2 = tie my %h2, 'IPC::Shareable', {
        key              => 'RW03',
        enforced_read_locking => 1,
        violated_read_lock_warn => 0,
        serializer       => 'storable',
    };

    $h1{a} = 10;
    $k1->lock(LOCK_EX);

    {
        local $SIG{__WARN__} = sub { fail "no-warn - unexpected warning: $_[0]" };
        my $val = $h2{a};
    }
    pass "no warning when violated_read_lock_warn is disabled";

    $k1->unlock;
}

# --- Both enforced_read_locking and violated_read_lock_warn disabled (degenerate) ---
{
    my $k1 = tie my %h1, 'IPC::Shareable', {
        key                     => 'RW05',
        create                  => 1,
        destroy                 => 1,
        enforced_read_locking   => 0,
        violated_read_lock_warn => 0,
        serializer              => 'storable',
    };
    my $k2 = tie my %h2, 'IPC::Shareable', {
        key                     => 'RW05',
        enforced_read_locking   => 0,
        violated_read_lock_warn => 0,
        serializer              => 'storable',
    };

    $h1{a} = 10;
    $k1->lock(LOCK_EX);

    {
        local $SIG{__WARN__} = sub { fail "ER=0 VR=0 - unexpected warning: $_[0]" };
        my $val = $h2{a};
    }
    pass "ER=0 VR=0: no warning when both enforced_read_locking and violated_read_lock_warn are disabled";

    $k1->unlock;
}

# --- Locked FETCH (LOCK_SH) does not warn ---
{
    my $k1 = tie my %h1, 'IPC::Shareable', {
        key              => 'RW04',
        create           => 1,
        destroy          => 1,
        enforced_read_locking => 1,
        violated_read_lock_warn => 1,
        serializer       => 'storable',
    };
    my $k2 = tie my %h2, 'IPC::Shareable', {
        key              => 'RW04',
        enforced_read_locking => 1,
        violated_read_lock_warn => 1,
        serializer       => 'storable',
    };

    $h1{a} = 10;

    $k2->lock(LOCK_SH);

    {
        local $SIG{__WARN__} = sub { fail "locked-fetch - unexpected warning: $_[0]" };
        my $val = $h2{a};
    }
    pass "no warning on FETCH when knot holds LOCK_SH (uses _data cache)";

    $k2->unlock;
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing;

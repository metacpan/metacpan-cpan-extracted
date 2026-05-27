use warnings;
use strict;

use IPC::Shareable qw(:lock);
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

# Regression: FETCH re-decoding inner child segments under LOCK_EX cascade
# caused a self-deadlock. _lock_children set SEM_WRITERS=1 on the child's
# semaphore, then FETCH called _decode_json_restore which tried LOCK_SH on
# the same semaphore — blocking on a lock the same process holds.
{
    tie my %top, 'IPC::Shareable', {
        key       => 'TOP_FETCH_DEADLOCK',
        create    => 1,
        destroy   => 1,
    };

    $top{0} = {};

    tie my $scalar, 'IPC::Shareable', {
        key       => 'SCALAR_FETCH_DEADLOCK',
        create    => 1,
        destroy   => 1,
    };
    $scalar = 'hello';

    $top{0}{shared}{key1} = \$scalar;

    my $knot = tied %top;

    local $SIG{ALRM} = sub { die "FETCH deadlocked\n" };
    alarm 5;
    my $ok = eval {
        $knot->lock(LOCK_EX, sub {
            $top{0};  # FETCH triggers the regression path
        });
        1;
    };
    alarm 0;

    ok $ok, "FETCH under LOCK_EX with nested separately-tied refs does not deadlock"
        or diag "eval error: $@";

    IPC::Shareable->clean_up_all;
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
my $sems_after = IPC::Shareable::sem_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};

is $segs_after, $segs_before, "All segments cleaned up ok";
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();
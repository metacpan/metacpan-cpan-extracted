use warnings;
use strict;

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok('IPC::Shareable');
};

IPC::Shareable->clean_up_testing('IPC::Shareable');
IPC::Shareable->testing_set('IPC::Shareable');

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

print "Starting with $segs_before segments\n";
is $segs_before, $segs_before, "Initial test ok";

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
is IPC::Shareable::seg_count(), $segs_before + 1, "No segs left after test suite run ok";

done_testing();
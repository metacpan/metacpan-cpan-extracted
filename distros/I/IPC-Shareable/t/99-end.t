use 5.006;
use strict;
use warnings;

use IPC::Shareable;
use Test::More;

BEGIN {
    use_ok( 'IPC::Shareable' ) || print "Bail out!\n";
}

IPC::Shareable->testing_set('IPC::Shareable');

# See t/00-base.t: the whole-suite global IPC count check is serial-only, so
# skip it under a parallel harness (eg. a smoker with HARNESS_OPTIONS=jN).
my $parallel = defined $ENV{HARNESS_OPTIONS} && $ENV{HARNESS_OPTIONS} =~ /(?:^|:)j[0-9]/;

my %store;
my $seg_ok = eval {
    tie %store, 'IPC::Shareable', {key => 'async_tests', destroy => 1, serializer => 'storable'};
    1;
};

if ($seg_ok) {
    my $start_segs = $store{segs};
    my $start_sems = $store{sems};

    IPC::Shareable::clean_up_all;

    my $segs = IPC::Shareable::seg_count();
    my $sems = IPC::Shareable::sem_count();

    SKIP: {
        skip "whole-suite IPC count check is serial-only (parallel harness detected)", 2
            if $parallel;
        is $segs, $start_segs, "All test segments cleaned up after test run";
        is $sems, $start_sems, "All test semaphores cleaned up after test run";
    }

    if ($ENV{PRINT_SEGS}) {
        warn "Started with $start_segs, ending with $segs\n";
    }
}
else {
    diag "async_tests segment not found; t/00-base.t may not have run. Skipping count comparison.";
}

done_testing();
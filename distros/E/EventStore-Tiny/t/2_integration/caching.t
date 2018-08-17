use strict;
use warnings;

use Test::More;

use_ok 'EventStore::Tiny';

# Prepare event store with event application counter (via logging)
my $ea_count    = 0;
my $est         = EventStore::Tiny->new(logger => sub {$ea_count++});
is $est->cache_distance => 0, 'Default cache size: 0';

# Prepare simple counter event
$est->register_event(EventApplied => sub {shift->{x}++});

my $cs = 100;
subtest "Cache size: $cs" => sub {
    $est->cache_distance($cs);

    # Fill with the cache size of events and some more, just because
    my $init_ec = $cs + 10;
    $est->store_event('EventApplied') for 1 .. $init_ec;

    # Snapshot: events applied
    is $est->snapshot->state->{x} => $init_ec, 'Correct state';
    is $ea_count => $init_ec, "$init_ec event applications";

    # Snapshot: 0 events applied
    $ea_count = 0;
    is $est->snapshot->state->{x} => $init_ec, 'Correct state';
    is $ea_count => 0, 'No new event applications';

    # Add $cs - 1 events
    $est->store_event('EventApplied') for 1 .. $cs;

    # Snapshot: $cs - 1 events applied
    $ea_count = 0;
    is $est->snapshot->state->{x} => $init_ec + $cs, 'Correct state';
    is $ea_count => $cs, ($cs) . ' new event applications';

    # Add 1 more event
    $est->store_event('EventApplied');

    # Snapshot: $cs events applied
    $ea_count = 0;
    is $est->snapshot->state->{x} => $init_ec + $cs + 1, 'Correct state';
    is $ea_count => $cs + 1, ($cs + 1) . ' event applications again';

    # Snapshot: 0 events applied
    $ea_count = 0;
    is $est->snapshot->state->{x} => $init_ec + $cs + 1, 'Correct state';
    is $ea_count => 0, 'No new event applications';
};

subtest 'Caching disabled' => sub {

    # Reset with cache_distance undef (caching disabled)
    $ea_count = 0;
    $est->events->events([]);
    $est->_cached_snapshot(undef);
    $est->cache_distance(undef);

    # Add some events
    my $ec = 17;
    $est->store_event('EventApplied') for 1 .. $ec;

    # Read state for the first time
    is $est->snapshot->state->{x} => $ec, "Correct state";
    is $ea_count => $ec, "$ec event applications";

    # Read again
    is $est->snapshot->state->{x} => $ec, 'Correct state';
    is $ea_count => 2 * $ec, "Again $ec event applications";
};

done_testing;

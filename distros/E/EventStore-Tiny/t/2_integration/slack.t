use strict;
use warnings;

use Test::More;
use Time::HiRes 'time';
use Clone 'clone';

use_ok 'EventStore::Tiny';

# Preparation method for event stores that have some work to do
sub work {
    my $es = shift;

    # Set up
    my $data_cells  = 10;
    my $data_points = 1_000;
    my $data_access = 1_000;

    # Event type
    $es->register_event(Answered => sub {
        my $state = shift; # No data neccessary here
        $state->{deep}[int rand $data_cells]{data}{rand()} = 42;
    });

    # Inject some data
    $es->store_event('Answered') for 1 .. $data_points;

    # Trigger event application
    # With caching on, this is slow because it calls 'clone' for each access
    $es->snapshot for 1 .. $data_access;
}

my $strict_runtime;
subtest 'Strict' => sub {

    # Prepare event store
    my $strict = EventStore::Tiny->new(
        logger          => undef,
        cache_distance  => 0, # Use caching. This is the default, but anyway
    );

    # Work
    my $start = time;
    work($strict);
    $strict_runtime = time - $start;

    # Time spent
    ok $strict_runtime > 0, 'Time spent';
    note "Strict runtime: $strict_runtime";

    subtest 'Strict data handling' => sub {
        $strict->snapshot->state->{deep}[3] = 17;
        isnt $strict->snapshot->state->{deep}[3] => 17, 'State preserved';
    };
};

subtest 'Slack' => sub {

    # Prepare non-strict event store
    my $slack = EventStore::Tiny->new(
        logger          => undef,
        cache_distance  => 0, # Use caching. This is the default, but anyway
        slack           => 1,
    );

    # Work
    my $start = time;
    work($slack);
    my $slack_runtime = time - $start;

    # Time spent
    ok $slack_runtime > 0, 'Time spent';
    note "Slack runtime: $slack_runtime";

    subtest 'Non-strict data handling' => sub {
        $slack->snapshot->state->{deep}[3] = 17;
        is $slack->snapshot->state->{deep}[3] => 17, 'State modified';
    };

    # Compare
    ok $slack_runtime < $strict_runtime * 0.2, 'Improved runtime';

    subtest 'Broken snapshot' => sub {
        $slack->register_event(Foo => sub {shift->{deep}[3] += 25});
        $slack->store_event('Foo' => {});
        is $slack->snapshot->state->{deep}[3] => 42, 'Modification continued';
    };
};

done_testing;

__END__

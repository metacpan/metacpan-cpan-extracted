use strict;
use warnings;

use Test::More;

use List::Util qw(sum);
use EventStore::Tiny::Event;

use_ok 'EventStore::Tiny::EventStream';

my @test_numbers = (17, 25, 42);

# Prepare events that add 17 or 25 or 42 to a state's "key" entry:
sub _test_events {
    return [map {
        my $add = $_;
        EventStore::Tiny::Event->new(name => 't', transformation => sub {
            $_[0]->{key} += $add;
        })
    } @test_numbers];
}

subtest 'Events at construction time' => sub {

    # Prepare test event storage
    my $tes = _test_events;

    # Construct event stream with an array of events
    my $es = EventStore::Tiny::EventStream->new(events => $tes);
    is $es->size => scalar(@test_numbers), 'Right event count';

    # Test event list members by applying
    for my $i (0 .. $#test_numbers) {
        is $es->events->[$i]->apply_to({})->{key} => $test_numbers[$i],
            "Correct transformation: $test_numbers[$i]";
    }
};

subtest 'Timestamp limits' => sub {

    # Prepare empty stream
    my $es = EventStore::Tiny::EventStream->new;
    is $es->first_timestamp => undef, 'First timestamp undefined';
    is $es->last_timestamp => undef, 'Last timestamp undefined';

    # Add events
    my $tes = _test_events;
    $es->events($tes);

    # Check limit timestamps
    is $es->first_timestamp => $tes->[0]->timestamp,
        'Correct first timestamp';
    is $es->last_timestamp => $tes->[$#$tes]->timestamp,
        'Correct last timestamp';
};

subtest 'Appending events' => sub {

    # Construct an empty event stream
    my $es = EventStore::Tiny::EventStream->new;
    is $es->size => 0, 'Right event count';

    # Add events
    $es->add_event($_) for @{+_test_events};
    is $es->size => scalar(@test_numbers), 'Right event count';

    # Test event list members by applying
    for my $i (0 .. $#test_numbers) {
        is $es->events->[$i]->apply_to({})->{key} => $test_numbers[$i],
            "Correct transformation: $test_numbers[$i]";
    }
};

subtest 'Application' => sub {

    # Construct event stream with an array of events
    my $es = EventStore::Tiny::EventStream->new(events => _test_events);

    subtest 'State given' => sub {

        # Prepare a test state to be modified
        my $init_foo    = 666;
        my $state       = {key => $init_foo};

        # Apply all events and check result
        $es->apply_to($state);
        is $state->{key} => sum($init_foo, @test_numbers),
            'Correct chained application of all events';
    };

    subtest 'No state given' => sub {
        is $es->apply_to->{key} => sum(@test_numbers),
            'Correct chained application of all events';
    };
};

subtest 'Extract substream' => sub {

    # Construct event stream with an array of events
    my $es = EventStore::Tiny::EventStream->new(events => _test_events);

    subtest 'Default' => sub {
        my $default = $es->substream;
        isa_ok $default => 'EventStore::Tiny::EventStream';
        is $default->size => $es->size, 'Same event count';
        is $default->apply_to->{key} => $es->apply_to->{key},
            'Correct chained application of the default events';
    };

    subtest 'Empty' => sub {
        my $empty = $es->substream(sub {return});
        isa_ok $empty => 'EventStore::Tiny::EventStream';
        is $empty->size => 0, 'No events left';
    };

    subtest 'First' => sub {
        my $count = 0;
        my $first = $es->substream(sub {$count++ == 0});
        isa_ok $first => 'EventStore::Tiny::EventStream';
        is $first->size => 1, 'Only one event left';

        # Check if it's the first
        is $first->apply_to->{key} => $test_numbers[0], 'Got the first event';
    };

    subtest 'All' => sub {
        my $all = $es->substream(sub {1});
        isa_ok $all => 'EventStore::Tiny::EventStream';
        is $all->size => $es->size, 'Same event count';
        is $all->apply_to->{key} => $es->apply_to->{key},
            'Correct chained application of all events';
    };
};

subtest 'Time substreams' => sub {

    # Prepare a separation timestamp
    my $events  = _test_events;
    my $sep_ts  = $events->[0]->timestamp;
    my $es      = EventStore::Tiny::EventStream->new(events => $events);

    subtest 'Events before' => sub {

        subtest 'Empty stream' => sub {
            my $empty_es = EventStore::Tiny::EventStream->new;
            is $empty_es->before(9**9**9)->size => 0, 'Empty result';
        };

        subtest 'Timestamp earlier than first timestamp' => sub {
            my $earlier_ts = $es->first_timestamp - 42;
            is $es->before($earlier_ts)->size => 0, 'Empty result';
        };

        subtest 'Timestamp is the last timestamp' => sub {
            is $es->before($es->last_timestamp) => $es, 'Same stream';
        };

        subtest 'Real substream' => sub {
            my $es_first = $es->before($sep_ts);
            is $es_first->size => 1, 'Correct substream size';
            is $es_first->apply_to->{key} => $test_numbers[0],
                'Correct event';
        };
    };

    subtest 'Events after' => sub {

        subtest 'Empty stream' => sub {
            my $empty_es = EventStore::Tiny::EventStream->new;
            is $empty_es->after(-9**9**9)->size => 0, 'Empty result';
        };

        subtest 'Timestamp later than the last timestamp' => sub {
            my $later_ts = $es->last_timestamp + 42;
            is $es->after($later_ts)->size => 0, 'Empty result';
        };

        subtest 'Real substream' => sub {
            my $es_rest = $es->after($sep_ts);
            is $es_rest->size => 2, 'Correct substream size';
            is $es_rest->apply_to->{key} => sum(@test_numbers[1,2]),
                'Correct events';
        };
    };
};

done_testing;

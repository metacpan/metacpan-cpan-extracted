use strict;
use warnings;

use Test::More;

use List::Util qw(sum);
use EventStore::Tiny::Event;

use_ok 'EventStore::Tiny::EventStream';

my @test_numbers = (17, 25, 42);

# prepare events that add 17 or 25 or 42 to a state's "key" entry:
sub _test_events {
    return [map {
        my $add = $_;
        EventStore::Tiny::Event->new(name => 't', transformation => sub {
            $_[0]->{key} += $add;
        })
    } @test_numbers];
}

subtest 'Events at construction time' => sub {

    # prepare test event storage
    my $tes = _test_events;

    # construct event stream with an array of events
    my $es = EventStore::Tiny::EventStream->new(events => $tes);
    is $es->length => scalar(@test_numbers), 'Right event count';

    # test event list members by applying
    for my $i (0 .. $#test_numbers) {
        is $es->events->[$i]->apply_to({})->{key} => $test_numbers[$i],
            "Correct transformation: $test_numbers[$i]";
    }
};

subtest 'Timestamp limits' => sub {

    # prepare empty stream
    my $es = EventStore::Tiny::EventStream->new;
    is $es->first_timestamp => undef, 'First timestamp undefined';
    is $es->last_timestamp => undef, 'Last timestamp undefined';

    # add events
    my $tes = _test_events;
    $es->events($tes);

    # check limit timestamps
    is $es->first_timestamp => $tes->[0]->timestamp,
        'Correct first timestamp';
    is $es->last_timestamp => $tes->[$#$tes]->timestamp,
        'Correct last timestamp';
};

subtest 'Appending events' => sub {

    # construct an empty event stream
    my $es = EventStore::Tiny::EventStream->new;
    is $es->length => 0, 'Right event count';

    # add events
    $es->add_event($_) for @{+_test_events};
    is $es->length => scalar(@test_numbers), 'Right event count';

    # test event list members by applying
    for my $i (0 .. $#test_numbers) {
        is $es->events->[$i]->apply_to({})->{key} => $test_numbers[$i],
            "Correct transformation: $test_numbers[$i]";
    }
};

subtest 'Application' => sub {

    # construct event stream with an array of events
    my $es = EventStore::Tiny::EventStream->new(events => _test_events);

    subtest 'State given' => sub {

        # prepare a test state to be modified
        my $init_foo    = 666;
        my $state       = {key => $init_foo};

        # apply all events and check result
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

    # construct event stream with an array of events
    my $es = EventStore::Tiny::EventStream->new(events => _test_events);

    subtest 'Default' => sub {
        my $default = $es->substream;
        isa_ok $default => 'EventStore::Tiny::EventStream';
        is $default->length => $es->length, 'Same event count';
        is $default->apply_to->{key} => $es->apply_to->{key},
            'Correct chained application of the default events';
    };

    subtest 'Empty' => sub {
        my $empty = $es->substream(sub {return});
        isa_ok $empty => 'EventStore::Tiny::EventStream';
        is $empty->length => 0, 'No events left';
    };

    subtest 'First' => sub {
        my $count = 0;
        my $first = $es->substream(sub {$count++ == 0});
        isa_ok $first => 'EventStore::Tiny::EventStream';
        is $first->length => 1, 'Only one event left';

        # check if it's the first
        is $first->apply_to->{key} => $test_numbers[0], 'Got the first event';
    };

    subtest 'All' => sub {
        my $all = $es->substream(sub {1});
        isa_ok $all => 'EventStore::Tiny::EventStream';
        is $all->length => $es->length, 'Same event count';
        is $all->apply_to->{key} => $es->apply_to->{key},
            'Correct chained application of all events';
    };
};

subtest 'Time substreams' => sub {

    # prepare events
    my $events  = _test_events;
    my $sep_ts  = $events->[0]->timestamp;
    my $es      = EventStore::Tiny::EventStream->new(events => $events);

    subtest 'Events until' => sub {
        my $es_first = $es->until($sep_ts);
        isa_ok $es_first => 'EventStore::Tiny::EventStream';
        is $es_first->length => 1, 'Correct substream length';
        is $es_first->apply_to->{key} => $test_numbers[0],
            'Correct event';
    };

    subtest 'Events after' => sub {
        my $es_rest = $es->after($sep_ts);
        isa_ok $es_rest => 'EventStore::Tiny::EventStream';
        is $es_rest->length => 2, 'Correct substream length';
        is $es_rest->apply_to->{key} => sum(@test_numbers[1,2]),
            'Correct events';
    };
};

done_testing;

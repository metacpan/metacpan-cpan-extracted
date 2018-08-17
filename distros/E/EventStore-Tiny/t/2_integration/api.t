use strict;
use warnings;

use Test::More;

use_ok 'EventStore::Tiny';

subtest 'Registration' => sub {

    # No events registered at the beginning
    my $est = EventStore::Tiny->new;
    is_deeply $est->event_names => [], 'No events stored at the beginning';

    # Register a simple event
    $est->register_event(AnswerGiven => sub {
        my ($state, $data) = @_;
        $state->{answer} = $data->{answer};
    });
    is_deeply $est->event_names => ['AnswerGiven'], 'Event name is known';
};

subtest 'Storing an event' => sub {

    # Prepare
    my $est = EventStore::Tiny->new;
    $est->register_event(AnswerGiven => sub {
        my ($state, $data) = @_;
        $state->{answer} = $data->{answer};
    });

    # Try to store unknown event
    eval {
        $est->store_event(UnknownEvent => {throw => 'exception plx'});
        fail 'No exception thrown';
    };
    like $@ => qr/Unknown event: UnknownEvent!/,
        'Correct exception for unknown event';

    # Store an event
    is $est->events->size => 0, 'No events';
    $est->store_event(AnswerGiven => {answer => 42});
    is $est->events->size => 1, 'One event after addition';

    # Test if it's the right event
    is $est->events->apply_to->{answer} => 42, 'Correct event added';
};

subtest 'Snapshot' => sub {

    # Register test events
    my $est = EventStore::Tiny->new;
    $est->register_event(TestEvent => sub {
        my ($state, $data) = @_;
        $state->{foo} += $data->{foo};
    });

    # Insert test events
    $est->store_event(TestEvent => {foo => $_}) for qw(17 25 42);

    subtest 'Unspecified snapshot' => sub {
        my $sn = $est->snapshot;
        isa_ok $sn => 'EventStore::Tiny::Snapshot';
        is $sn->timestamp => $est->events->last_timestamp,
            'Correct snapshot timestamp';
        is $sn->state->{foo} => 84, 'Correct snapshot';
    };

    subtest 'Specified timestamp snapshot' => sub {
        my $sep_ts = $est->events->events->[1]->timestamp;
        my $sn = $est->snapshot($sep_ts);
        isa_ok $sn => 'EventStore::Tiny::Snapshot';
        is $sn->timestamp => $sep_ts, 'Correct snapshot timestamp';
        is $sn->state->{foo} => 42, 'Correct snapshot';
    };

    subtest 'Verification' => sub {

        for my $i (0 .. $#{$est->events->events}) {
            my $subtest_name = 'Correct ' . ($i + 1);

            subtest $subtest_name => sub {

                # Create a correct snapshot
                my $sep_ts = $est->events->events->[$i]->timestamp;
                my $correct_sn = EventStore::Tiny::Snapshot->new(
                    state       => $est->events->before($sep_ts)->apply_to,
                    timestamp   => $sep_ts,
                );

                # Verify
                ok $est->is_correct_snapshot($correct_sn), 'Verified';
            };
        }

        subtest 'Incorrect' => sub {

            # Create an incorrect snapshot
            my $incorrect_sn = EventStore::Tiny::Snapshot->new(
                state       => {xnorfzt => 666},
                timestamp   => $est->events->events->[1]->timestamp,
            );

            # Verify
            ok not($est->is_correct_snapshot($incorrect_sn)), 'Not verified';
        };
    };
};

done_testing;

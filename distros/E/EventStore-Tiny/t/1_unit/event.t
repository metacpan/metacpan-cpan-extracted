use strict;
use warnings;

use Test::More;

use_ok 'EventStore::Tiny::Event';
use_ok 'EventStore::Tiny::DataEvent';

subtest 'Defaults' => sub {

    subtest 'UUID' => sub {

        # Init and check UUID
        my $ev = EventStore::Tiny::Event->new(name => 'foo');
        ok defined $ev->uuid, 'Event has an UUID';
        like $ev->uuid => qr/^(\w+-){4}\w+$/, 'UUID looks like an UUID string';

        # Check another event's UUID
        my $ev2 = EventStore::Tiny::Event->new(name => 'foo');
        isnt $ev->uuid => $ev2->uuid, 'Two different UUIDs';
    };

    subtest 'High-resolution timestamp' => sub {

        # Init and check timestamp
        my $ev = EventStore::Tiny::Event->new(name => 'foo');
        ok defined $ev->timestamp, 'Event has a timestamp';
        like $ev->timestamp => qr/^\d+\.\d+$/, 'Timestamp looks like a decimal';
        isnt $ev->timestamp => time, 'Timestamp is not the integer timestamp';

        # Check another event's timestamp
        my $ev2 = EventStore::Tiny::Event->new(name => 'foo');
        isnt $ev->timestamp => $ev2->timestamp, 'Time has passed.';
    };

    subtest 'Name' => sub {
        eval {EventStore::Tiny::Event->new};
        like $@ => qr/name is required/, 'Name is required';
    };

    subtest 'Transformation' => sub {
        my $tr = EventStore::Tiny::Event->new(name => 'foo')->transformation;
        is ref($tr) => 'CODE', 'ISA subref';
        is $tr->($_), undef, 'Does nothing';
    };

    subtest 'Summary' => sub {
        my $e = EventStore::Tiny::Event->new(name => 'foo');
        ok defined $e->summary, 'Summary is defined';

        # Summary matcher
        my $summary_rx = qr/^\[
            foo                     # Name
            \s \(
                \d\d\d\d-\d\d-\d\d  # Date
                T                   # ISO 8601 separator
                \d\d:\d\d:\d\d      # Time
                (\.\d+)?            # Optional: high res time
            \)
        \]$/x;

        # Match with high-res timestamp
        like $e->summary => $summary_rx, 'Correct summary';
        $e->summary =~ $summary_rx;
        ok defined $1, 'Decimals represented in summary';

        # Strip decimals
        $e->timestamp(42);
        like $e->summary => $summary_rx, 'Correct summary';
        $e->summary =~ $summary_rx;
        ok not(defined $1), 'No decimals represented in summary';
    };
};

subtest 'Construction arguments' => sub {

    # Construct
    my $ev = EventStore::Tiny::Event->new(
        name            => 'foo',
        transformation  => sub {25 + shift},
    );

    # Check
    is $ev->name => 'foo', 'Correct name';
    is $ev->transformation->(17) => 42, 'Correct transformation';
};

subtest 'Application' => sub {

    # Create event
    my $ev = EventStore::Tiny::Event->new(
        name            => 'bar',
        transformation  => sub {
            my $state = shift;
            $state->{quux} += 25;
            return 666; # return value makes no sense
        },
    );

    # Prepare state for application
    my $state = {};
    $state->{quux} = 17;

    # Apply
    my $ret_val = $ev->apply_to($state);
    is $state->{quux} => 42, 'Correct modified state';
    is $ret_val => $state, 'Return state is the same as given state';
};

subtest 'Data event' => sub {

    # Check defaults
    my $ev = EventStore::Tiny::DataEvent->new(name => 'quux');
    is_deeply $ev->data => {}, 'Default data is an empty hash';

    # Construct data-driven event
    $ev = EventStore::Tiny::DataEvent->new(
        name            => 'foo',
        transformation  => sub {
            my ($state, $data) = @_;
            $state->{$data->{key}} = 42;
        },
        data            => {key => 'quux'},
    );

    # Apply to empty state
    is $ev->apply_to({})->{quux} => 42, 'Correct state-update from data';

    subtest 'Summarizing summary' => sub {

        # Extended summary regex
        my $summary_rx = qr/^\[
            foo                     # Name
            \s \(
                \d\d\d\d-\d\d-\d\d  # Date
                T                   # ISO 8601 separator
                \d\d:\d\d:\d\d      # Time
                (?:\.\d+)?          # Optional: high res time
            \)
            \s \| \s
            (.*)                    # Data representation
        \]$/x;

        # Prepare expected results
        my %expected = (
            'quux'                      => 'quux',
            "A    \nB\n\n\nC     D\n"   => 'A B C D',
            '123456789012345678'        => '123456789012345678',
            '1234567890123456789'       => '1234567890123456789',
            '12345678901234567890'      => '12345678901234567...',
            '123456789012345678901'     => '12345678901234567...',
            "12345678901\n4'6' ABCDEF"  => '12345678901 46 AB...',
        );

        # Check
        for my $ed (sort keys %expected) {
            $ev->data->{key} = $ed;
            like $ev->summary => $summary_rx, 'Correct extended summary';
            $ev->summary =~ $summary_rx;
            is $1 => "key: '$expected{$ed}'",
                "Correct data summary $expected{$ed}";
        }
    };
};

subtest 'Specialization' => sub {

    # Construct data-driven event
    my $ev = EventStore::Tiny::Event->new(
        name            => 'foo',
        transformation  => sub {
            my ($state, $data) = @_;
            $state->{$data->{key}} = 42;
        },
    );

    # Specialize
    my $de = EventStore::Tiny::DataEvent->new_from_template(
        $ev, {key => 'quux'}
    );
    isa_ok $de => 'EventStore::Tiny::DataEvent';

    # Apply to empty state
    is $de->apply_to({})->{quux} => 42, 'Correct state-update from new data';
};

done_testing;

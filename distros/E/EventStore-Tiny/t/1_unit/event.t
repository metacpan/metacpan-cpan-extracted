use strict;
use warnings;

use Test::More;

use_ok 'EventStore::Tiny::Event';
use_ok 'EventStore::Tiny::DataEvent';

subtest 'Default UUID' => sub {

    # init and check UUID
    my $ev = EventStore::Tiny::Event->new(name => 'foo');
    ok defined $ev->uuid, 'Event has an UUID';
    like $ev->uuid => qr/^(\w+-){4}\w+$/, 'UUID looks like an UUID string';

    # check another event's UUID
    my $ev2 = EventStore::Tiny::Event->new(name => 'foo');
    isnt $ev->uuid => $ev2->uuid, 'Two different UUIDs';
};

subtest 'Default high-resolution timestamp' => sub {

    # init and check timestamp
    my $ev = EventStore::Tiny::Event->new(name => 'foo');
    ok defined $ev->timestamp, 'Event has a timestamp';
    like $ev->timestamp => qr/^\d+\.\d+$/, 'Timestamp looks like a decimal';
    isnt $ev->timestamp => time, 'Timestamp is not the integer timestamp';

    # check another event's timestamp
    my $ev2 = EventStore::Tiny::Event->new(name => 'foo');
    isnt $ev->timestamp => $ev2->timestamp, 'Time has passed.';
};

subtest 'Construction arguments' => sub {

    # construct
    my $ev = EventStore::Tiny::Event->new(
        name            => 'foo',
        transformation  => sub {25 + shift},
    );

    # check
    is $ev->name => 'foo', 'Correct name';
    is $ev->transformation->(17) => 42, 'Correct transformation';
};

subtest 'Application' => sub {

    # create event
    my $ev = EventStore::Tiny::Event->new(
        name            => 'bar',
        transformation  => sub {
            my $state = shift;
            $state->{quux} += 25;
            return 666; # return value makes no sense
        },
    );

    # prepare state for application
    my $state = {};
    $state->{quux} = 17;

    # apply
    my $ret_val = $ev->apply_to($state);
    is $state->{quux} => 42, 'Correct modified state';
    is $ret_val => $state, 'Return state is the same as given state';
};

subtest 'Data event' => sub {

    # construct data-driven event
    my $ev = EventStore::Tiny::DataEvent->new(
        name            => 'foo',
        transformation  => sub {
            my ($state, $data) = @_;
            $state->{$data->{key}} = 42;
        },
        data            => {key => 'quux'},
    );

    # apply to empty state
    is $ev->apply_to({})->{quux} => 42, 'Correct state-update from data';
};

subtest 'Specialization' => sub {

    # construct data-driven event
    my $ev = EventStore::Tiny::Event->new(
        name            => 'foo',
        transformation  => sub {
            my ($state, $data) = @_;
            $state->{$data->{key}} = 42;
        },
    );

    # specialize
    my $de = EventStore::Tiny::DataEvent->new_from_template(
        $ev, {key => 'quux'}
    );
    isa_ok $de => 'EventStore::Tiny::DataEvent';

    # apply to empty state
    is $de->apply_to({})->{quux} => 42, 'Correct state-update from new data';
};

done_testing;

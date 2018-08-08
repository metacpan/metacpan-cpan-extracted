use strict;
use warnings;

use Test::More;

use EventStore::Tiny;
use File::Temp qw(tmpnam);
use Storable;

# prepare a test event store
my $es = EventStore::Tiny->new(logger => undef);

# prepare events
$es->register_event(FooTested => sub {
    my ($state, $data) = @_;
    $state->{$data->{name}} = 17;
});
$es->store_event(FooTested => {name => 'test_field'});
$es->register_event(BarTested => sub {
    my ($state, $data) = @_;
    $state->{$data->{name}} += 25;
});
$es->store_event(BarTested => {name => 'test_field'});
$es->register_event(BazTested => sub {
    my ($state, $data) = @_;
    $state->{quux} = $data->{quux};
});
$es->store_event(BazTested => {quux => 666});

sub test_events {
    my ($name, $store) = @_;
    subtest "$name events" => sub {

    # test resulting events
    is $es->events->size => 3, 'Got 3 events';
    my $e1 = $es->events->events->[0];
    is $e1->name => 'FooTested', 'Correct first event name';
    is_deeply $e1->data => {name => 'test_field'},
        'Correct first event data';
    my $e2 = $es->events->events->[1];
    is $e2->name => 'BarTested', 'Correct second event name';
    is_deeply $e2->data => {name => 'test_field'},
        'Correct second event data';
    my $e3 = $es->events->events->[2];
    is $e3->name => 'BazTested', 'Correct third event name';
    is_deeply $e3->data => {quux => 666},
        'Correct third event data';

    # test resulting state
    is_deeply $es->snapshot->state => {
        test_field  => 42,
        quux        => 666,
    }, 'Correct state data after event application';
}}

# test prepared events
test_events(Prepared => $es);

# store and load roundtrip
my $tmp_fn = tmpnam;
$es->store_to_file($tmp_fn);
my $nes = EventStore::Tiny->new_from_file($tmp_fn);
isa_ok $nes => 'EventStore::Tiny';

# test loaded events
test_events(Loaded => $nes);

done_testing;

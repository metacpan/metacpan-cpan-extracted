use strict;
use warnings;

use Test::More;

use EventStore::Tiny;
use File::Temp qw(tmpnam);

# Prepare event registration
sub register_events {
    my $es = shift;

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
}

# Prepare event tests
sub test_events {
    my ($name, $es) = @_;
    subtest "$name events" => sub {

    # Test resulting events
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

    # Test resulting state
    is_deeply $es->snapshot->state => {
        test_field  => 42,
        quux        => 666,
    }, 'Correct state data after event application';
}}

# Prepare a test event store
my $es = EventStore::Tiny->new(logger => undef);
register_events($es);

# Test prepared events
test_events(Prepared => $es);

# Store and load roundtrip
my $tmp_fn = tmpnam;
$es->export_events($tmp_fn);
my $nes = EventStore::Tiny->new(logger => undef);
register_events($nes);
$nes->import_events($tmp_fn);

# Test loaded events
test_events(Loaded => $nes);

done_testing;

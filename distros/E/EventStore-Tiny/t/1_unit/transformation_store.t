use strict;
use warnings;

use Test::More;

use_ok 'EventStore::Tiny::TransformationStore';

# Create
my $ts = EventStore::Tiny::TransformationStore->new;

subtest 'Reading from empty' => sub {
    is_deeply [$ts->names] => [], 'Empty names list';
    is $ts->get('Foo') => undef, 'Transformation undefined';
};

subtest 'Inject' => sub {
    $ts->set(Foo => sub {shift->{answer} = 42});
    is_deeply [$ts->names] => ['Foo'], 'Foo in names list';
    
    # Test transformation
    my $state = {answer => 17};
    $ts->get('Foo')->($state);
    is_deeply $state => {answer => 42}, 'Correct state transformation';
};

subtest 'Update not possible' => sub {
    eval {
        $ts->set(Foo => sub {shift->{bar} = 17});
        fail 'No exception thrown';
    };
    like $@ => qr/Event Foo cannot be replaced/, 'Correct exception message';

    # Test transformation: still the same
    my $state = {answer => 17};
    $ts->get('Foo')->($state);
    is_deeply $state => {answer => 42}, 'Correct state transformation';
};

done_testing;

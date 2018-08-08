use strict;
use warnings;

use Test::More;

use_ok 'EventStore::Tiny::Snapshot';

subtest 'Defaults' => sub {

    subtest 'State' => sub {
        eval {EventStore::Tiny::Snapshot->new(timestamp => 42)};
        like $@ => qr/state is required/, 'State is required';
    };

    subtest 'Timestamp' => sub {
        eval {EventStore::Tiny::Snapshot->new(state => {})};
        like $@ => qr/timestamp is required/, 'Timestamp is required';
    };
};

done_testing;

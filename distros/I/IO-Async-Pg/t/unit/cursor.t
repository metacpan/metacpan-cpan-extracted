use strict;
use warnings;
use Test2::V0;

use IO::Async::Pg::Cursor;

subtest 'constructor' => sub {
    my $cursor = IO::Async::Pg::Cursor->new(
        name       => 'test_cursor',
        batch_size => 100,
    );

    isa_ok $cursor, 'IO::Async::Pg::Cursor';
    is $cursor->name, 'test_cursor', 'name accessor';
    is $cursor->batch_size, 100, 'batch_size accessor';
    ok !$cursor->is_exhausted, 'not exhausted initially';
};

subtest 'default batch size' => sub {
    my $cursor = IO::Async::Pg::Cursor->new(
        name => 'test_cursor',
    );

    is $cursor->batch_size, 1000, 'default batch_size is 1000';
};

subtest 'auto-generated name' => sub {
    my $cursor1 = IO::Async::Pg::Cursor->new();
    my $cursor2 = IO::Async::Pg::Cursor->new();

    like $cursor1->name, qr/^cursor_\d+$/, 'auto-generated name format';
    isnt $cursor1->name, $cursor2->name, 'unique names generated';
};

done_testing;

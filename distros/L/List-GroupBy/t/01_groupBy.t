use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

use List::GroupBy qw( groupBy );

my @list = (
    { firstname => 'Fred',   surname => 'Blogs', age => 20 },
    { firstname => 'George', surname => 'Blogs', age => 30 },
    { firstname => 'Fred',   surname => 'Blogs', age => 65 },
    { firstname => 'George', surname => 'Smith', age => 32 },
    { age => 99 },
);

subtest 'Simple calling options' => sub {
    my %groupedList = groupBy ( [ 'surname', 'firstname' ], @list );

    cmp_deeply(
        \%groupedList,
        {
            Blogs => {
                Fred => [
                    { firstname => 'Fred',   surname => 'Blogs', age => 20 },
                    { firstname => 'Fred',   surname => 'Blogs', age => 65 },
                ],
                George => [
                    { firstname => 'George', surname => 'Blogs', age => 30 },
                ],
            },
            Smith => {
                George => [
                    { firstname => 'George', surname => 'Smith', age => 32 },
                ],
            },
            '' => {
                '' => [
                    { age => 99 },

                ],
            },
        },
        "Our grouped list should match the hash we expect"
    );

    %groupedList = groupBy ({ keys => [ 'surname', 'firstname' ] }, @list );

    cmp_deeply(
        \%groupedList,
        {
            Blogs => {
                Fred => [
                    { firstname => 'Fred',   surname => 'Blogs', age => 20 },
                    { firstname => 'Fred',   surname => 'Blogs', age => 65 },
                ],
                George => [
                    { firstname => 'George', surname => 'Blogs', age => 30 },
                ],
            },
            Smith => {
                George => [
                    { firstname => 'George', surname => 'Smith', age => 32 },
                ],
            },
            '' => {
                '' => [
                    { age => 99 },

                ],
            },
        },
        "Our grouped list should match the hash we expect even if we use the more advance call method"
    );

    throws_ok { groupBy( @list ) } qr/missing grouping keys/, "if we miss the arrayref or keys then we should error";
};

subtest 'Advanced calling option' => sub {
    my %groupedList = groupBy ( { keys => [ 'surname', 'firstname' ], defaults => { surname => 'Blogs' } }, @list );

    cmp_deeply(
        \%groupedList,
        {
            Blogs => {
                Fred => [
                    { firstname => 'Fred',   surname => 'Blogs', age => 20 },
                    { firstname => 'Fred',   surname => 'Blogs', age => 65 },
                ],
                George => [
                    { firstname => 'George', surname => 'Blogs', age => 30 },
                ],
                '' => [
                    { age => 99 },
                ],
            },
            Smith => {
                George => [
                    { firstname => 'George', surname => 'Smith', age => 32 },
                ],
            },
        },
        "Our grouped list should match the hash we expect"
    );

    throws_ok { groupBy( @list ) } qr/missing grouping keys/, "if we miss the arrayref or keys then we should error";

    throws_ok { groupBy ( { keys => [ 'surname', 'firstname' ], defaults => [ surname => 'Blogs' ] }, @list ) } qr/defaults should be a hashref/, "if we use something other than a hashref for defaults we should error";


    %groupedList = groupBy (
        {
            keys => [ 'surname', 'firstname' ],
            defaults => { surname => 'Blogs' },
            operations => { surname => sub { uc $_[0] } },
        },
        @list
    );

    cmp_deeply(
        \%groupedList,
        {
            BLOGS => {
                Fred => [
                    { firstname => 'Fred',   surname => 'Blogs', age => 20 },
                    { firstname => 'Fred',   surname => 'Blogs', age => 65 },
                ],
                George => [
                    { firstname => 'George', surname => 'Blogs', age => 30 },
                ],
                '' => [
                    { age => 99 },
                ],
            },
            SMITH => {
                George => [
                    { firstname => 'George', surname => 'Smith', age => 32 },
                ],
            },
        },
        "Our primary key should have used the specified operation when grouping"
    );

    throws_ok { groupBy ( { keys => [ 'surname', 'firstname' ], operations => [] }, @list ) } qr/operations should be a hashref/, "if we use something other than a hashref for operations then we should error";
    throws_ok { groupBy ( { keys => [ 'surname', 'firstname' ], operations => { surname => 1 } }, @list ) } qr/operation defined should be an anonymous sub/, "if we use something other than an anonymous sub as an operation then we should error";
};

done_testing();

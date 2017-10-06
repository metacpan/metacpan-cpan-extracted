use strict;
use warnings;
use Test::More;
use List::ToHash qw/to_hash/;

is_deeply(
    (to_hash { } ()),
    {},
);

is_deeply(
    (to_hash { } (1, 2, 3)),
    {},
);

is_deeply(
    (to_hash { undef } (undef)),
    {}
);

is_deeply(
    (
        to_hash { $_->{id} }
        {id => 'a', value => 1}, {id => 'b', value => 2}
    ),
    {
        a => {
            id    => 'a',
            value => 1,
        },
        b => {
            id    => 'b',
            value => 2,
        },
    },
);

is_deeply(
    (
        to_hash { $_->[0] }
        ['a', 1], ['b', 2]
    ),
    {
        a => ['a', 1],
        b => ['b', 2],
    },
);

is_deeply(
    (
        to_hash { $_->[0] }
        [1, 'a'], [2, 'b'], [2, 'c']
    ),
    {
        1 => [1, 'a'],
        2 => [2, 'c'],
    },
);

is_deeply(
    (
        to_hash { $_->{id} }
        {id => 'a', value => 1}, {id => '', value => 2}, {value => 3},
    ),
    {
        a => {
            id    => 'a',
            value => 1,
        },
        '' => {
            id    => '',
            value => 2,
        },
    },
);


done_testing;

use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 12 }
use Clone qw(clone);

use Hex::Record;

my $hex_original = Hex::Record->new(
    parts => [
        {
            start => 0x0,
            bytes => [
                qw(00),
            ],
        },
        {
            start => 0x10,
            bytes => [
                qw(00 11 22),
            ],
        },
        {
            start => 0x100,
            bytes => [
                qw(00 01 02 03 04 05 06 07 08 09
                   10 11 12 13 14 15 16 17 18 19
                   20 21 22 23 24 25 26 27 28 29
                   30 31 32 33 34 35 36 37 38 39
                   40 41 42 43 44 45 46 47 48 49),
            ],
        },
        {
            start => 0x1000,
            bytes => [
                qw(FF FF FF),
            ],
        },
    ],
);

my @remove_bytes_tests = (
    {
        from  => 0,
        count => 0x1001,
        expected_parts => [
            {
                start => 0x1001,
                bytes => [
                    qw(FF FF),
                ],
            },
        ],
    },
    {
        from  => 0,
        count => 1,
        expected_parts => [
            {
                start => 0x10,
                bytes => [
                    qw(00 11 22),
                ],
            },
            {
                start => 0x100,
                bytes => [
                    qw(00 01 02 03 04 05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            },
            {
                start => 0x1000,
                bytes => [
                    qw(FF FF FF),
                ],
            },
        ],
    },
    {
        from  => 0,
        count => 19,
        expected_parts => [
            {
                start => 0x100,
                bytes => [
                    qw(00 01 02 03 04 05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            },
            {
                start => 0x1000,
                bytes => [
                    qw(FF FF FF),
                ],
            },
        ],
    },
    {
        from  => 0,
        count => 306,
        expected_parts => [
            {
                start => 0x1000,
                bytes => [
                    qw(FF FF FF),
                ],
            },
        ],
    },
    {
        from  => 0,
        count => 4099,
        expected_parts => [],
    },
    {
        from  => 0x100,
        count => 5,
        expected_parts => [
            {
                start => 0x0,
                bytes => [
                    qw(00),
                ],
            },
            {
                start => 0x10,
                bytes => [
                    qw(00 11 22),
                ],
            },
            {
                start => 0x105,
                bytes => [
                    qw(               05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            },
            {
                start => 0x1000,
                bytes => [
                    qw(FF FF FF),
                ],
            },
        ],
    },
    {
        from  => 0x11,
        count => 2,
        expected_parts => [
            {
                start => 0x0,
                bytes => [
                    qw(00),
                ],
            },
            {
                start => 0x10,
                bytes => [
                    qw(00),
                ],
            },
            {
                start => 0x100,
                bytes => [
                    qw(00 01 02 03 04 05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            },
            {
                start => 0x1000,
                bytes => [
                    qw(FF FF FF),
                ],
            },
        ],
    },
    {
        from  => 0x10,
        count => 3,
        expected_parts => [
            {
                start => 0x0,
                bytes => [
                    qw(00),
                ],
            },
            {
                start => 0x100,
                bytes => [
                    qw(00 01 02 03 04 05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            },
            {
                start => 0x1000,
                bytes => [
                    qw(FF FF FF),
                ],
            },
        ],
    },
    {
        from  => 0,
        count => 1000000000000000000000000000,
        expected_parts => [],
    },
    {
        from  => 0x105,
        count => 5,
        expected_parts => [
            {
                start => 0x0,
                bytes => [
                    qw(00),
                ],
            },
            {
                start => 0x10,
                bytes => [
                    qw(00 11 22),
                ],
            },
            {
                start => 0x100,
                bytes => [
                    qw(00 01 02 03 04)
                ],
            },
            {
                start => 0x10A,
                bytes => [
                    qw(10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            },
            {
                start => 0x1000,
                bytes => [
                    qw(FF FF FF),
                ],
            },
        ],
    },
    {
        from  => 0x105,
        count => 5,
        expected_parts => [
            {
                start => 0x0,
                bytes => [
                    qw(00),
                ],
            },
            {
                start =>  0x10,
                bytes => [
                    qw(00 11 22),
                ],
            },
            {
                start => 0x100,
                bytes => [
                    qw(00 01 02 03 04)
                ],
            },
            {
                start => 0x10A,
                bytes => [
                    qw(10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            },
            {
                start => 0x1000,
                bytes => [
                    qw(FF FF FF)
                ],
            },
        ],
    },
    {
        from  => 0x08,
        count => 4000,
        expected_parts => [
            {
                start => 0x0,
                bytes => [
                    qw(00),
                ],
            },
            {
                start => 0x1000,
                bytes => [
                    qw(FF FF FF)
                ],
            },
        ],
    },
);

for my $remove_bytes_test (@remove_bytes_tests) {
    my $hex_copy = clone $hex_original;

    my $from  = $remove_bytes_test->{from};
    my $count = $remove_bytes_test->{count};

    $hex_copy->remove($from, $count);

    is_deeply(
        $hex_copy->{parts},
        $remove_bytes_test->{expected_parts},
        "successfully removed $count bytes from $from"
    );
}


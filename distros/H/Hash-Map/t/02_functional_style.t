#!perl -T

use strict;
use warnings;

use Test::More tests => 8 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    use_ok( 'Hash::Map', qw(hash_map hashref_map) );
}

eq_or_diff(
    {
        hash_map(
            {
                a => 11,
                b => 12,
                c => 13,
            },
            [ qw(a b) ],
        )
    },
    {
        a   => 11,
        b   => 12,
    },
    'hash_map copy_keys',
);

eq_or_diff(
    scalar hashref_map(
        {
            a => 21,
            b => 22,
            c => 23,
        },
        [
            qw(b c),
            sub {
                isa_ok(
                    shift,
                    'Hash::Map',
                    'check object in hashref_map copy_keys',
                );
                return "p_$_";
            },
        ],
    ),
    {
        p_b => 22,
        p_c => 23,
    },
    'hashref_map copy_keys (with sub is map_keys)',
);

eq_or_diff(
    scalar hashref_map(
        {
            a => 31,
            b => 32,
            c => 33,
        },
        {
            a => q{b},
            b => q{c},
        },
    ),
    {
        b => 31,
        c => 32,
    },
    'hashref_map map_keys',
);

eq_or_diff(
    scalar hashref_map(
        {
            a => 41,
            b => 42,
            c => 43,
        },
        [ qw(a) ],
        {
            a => sub {
                isa_ok(
                    shift,
                    'Hash::Map',
                    'check object in hashref_map copy + modify',
                );
                return "p_$_";
            },
        },
    ),
    {
        a => 'p_41',
    },
    'hashref_map copy + modify',
);

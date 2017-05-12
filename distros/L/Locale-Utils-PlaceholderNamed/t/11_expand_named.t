#!perl -T

use strict;
use warnings;

use Test::More tests => 10;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    use_ok 'Locale::Utils::PlaceholderNamed';
}

my $obj = Locale::Utils::PlaceholderNamed->new;

is_deeply
    [ $obj->expand_named ],
    [ undef ],
    'undef';
eq_or_diff
    $obj->expand_named('{a} {b} {c} {d}'),
    '{a} {b} {c} {d}',
    'expand empty';
eq_or_diff
    $obj->expand_named(
        '{a} {b} {c} {d}',
        a => 'a',
        b => 2,
        c => '345678.90',
        d => 45678.90,
    ),
    'a 2 345678.90 45678.9',
    'expand hash';
eq_or_diff
    $obj->expand_named(
        '{a} {b} {c} {d}',
        {
            a => 'a',
            b => 2,
            c => '345678.90',
            d => 45678.90,
        },
    ),
    'a 2 345678.90 45678.9',
    'expand hash_ref';
eq_or_diff
    $obj->expand_named(
        '{a} {b} {c} {d}',
        {},
    ),
    '{a} {b} {c} {d}',
    'expand empty hash_ref';
eq_or_diff
    $obj->expand_named(
        'foo {plus} bar {plus} baz = {num} items',
        plus  => q{+},
        num   => 3,
    ),
    'foo + bar + baz = 3 items',
    'same placeholder double';

$obj->is_strict(1);
eq_or_diff
    $obj->expand_named(
        'foo {name}',
        name => undef,
    ),
    'foo {name}',
    'undef, strict';

$obj->is_strict(0);
eq_or_diff
    $obj->expand_named(
        'foo {name}',
        name => undef,
    ),
    'foo ',
    'undef, no strict';

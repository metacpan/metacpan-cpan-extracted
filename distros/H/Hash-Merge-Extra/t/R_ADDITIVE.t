#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;

use Hash::Merge qw(merge);
use Hash::Merge::Extra;

ok(
    Hash::Merge::set_behavior('R_ADDITIVE')
) || BAIL_OUT('Failed to set behavior');

my ($got, @tests);

@tests = (
    {
        one => 'alpha',
        two => undef,
        out => 'alpha',
        msg => "scalar vs undef",
    },
    {
        one => 'alpha',
        two => 'beta',
        out => 'beta',
        msg => "scalar vs scalar",
    },
    {
        one => 'alpha',
        two => [],
        out => [],
        msg => "scalar vs array",
    },
    {
        one => 'alpha',
        two => {},
        out => {},
        msg => "scalar vs hash",
    },
    {
        one => [],
        two => undef,
        out => [],
        msg => "array vs undef",
    },
    {
        one => [0, 1],
        two => 'beta',
        out => 'beta',
        msg => "array vs scalar",
    },
    {
        one => [0, 1],
        two => [1, 2],
        out => [1, 2, 0, 1],
        msg => "array vs array",
    },
    {
        one => [0, 1],
        two => {a => 0, b => 1},
        out => {a => 0, b => 1},
        msg => "array vs hash",
    },
    {
        one => {},
        two => undef,
        out => {},
        msg => "hash vs undef",
    },
    {
        one => {a => 0, b => 1},
        two => 'beta',
        out => 'beta',
        msg => "hash vs scalar",
    },
    {
        one => {a => 0, b => 1},
        two => [1, 2],
        out => [1, 2],
        msg => "hash vs array",
    },
    {
        one => {a => 0, b => 1},
        two => {a => 9, c => 2},
        out => {a => 9, b => 1, c => 2},
        msg => "hash vs hash",
    },
);

for (@tests) {
    $got = merge($_->{one}, $_->{two});
    is_deeply($got, $_->{out}, $_->{msg}) ||
        diag explain $got;
}

done_testing(@tests + 1);

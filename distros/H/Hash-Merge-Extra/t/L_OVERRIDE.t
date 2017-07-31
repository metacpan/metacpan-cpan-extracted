#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;

use Hash::Merge qw(merge);
use Hash::Merge::Extra;

ok(
    Hash::Merge::set_behavior('L_OVERRIDE')
) || BAIL_OUT('Failed to set behavior');

my ($got, @tests);

@tests = (
    {
        one => 'alpha',
        two => 'beta',
        out => 'alpha',
        msg => "scalar vs scalar",
    },
    {
        one => 'alpha',
        two => [],
        out => 'alpha',
        msg => "scalar vs array",
    },
    {
        one => 'alpha',
        two => {},
        out => 'alpha',
        msg => "scalar vs hash",
    },
    {
        one => [0, 1],
        two => 'beta',
        out => [0, 1],
        msg => "array vs scalar",
    },
    {
        one => [0, 1],
        two => [1, 2],
        out => [0, 1],
        msg => "array vs array",
    },
    {
        one => [0, 1],
        two => {a => 0, b => 1},
        out => [0, 1],
        msg => "array vs hash",
    },
    {
        one => {a => 0, b => 1},
        two => 'beta',
        out => {a => 0, b => 1},
        msg => "hash vs scalar",
    },
    {
        one => {a => 0, b => 1},
        two => [1, 2],
        out => {a => 0, b => 1},
        msg => "hash vs array",
    },
    {
        one => {a => 0, b => 1},
        two => {a => 9, c => 2},
        out => {a => 0, b => 1, c => 2},
        msg => "hash vs hash",
    },
);

for (@tests) {
    $got = merge($_->{one}, $_->{two});
    is_deeply($got, $_->{out}, $_->{msg}) ||
        diag explain $got;
}

done_testing(@tests + 1);

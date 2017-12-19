#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;

use Hash::Merge qw(merge);
use Hash::Merge::Extra;

ok(
    Hash::Merge::set_behavior('R_MERGE_PATCH')
) || BAIL_OUT('Failed to set behavior');

my ($got, @tests);

@tests = (
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
        one => [0, 1],
        two => 'beta',
        out => 'beta',
        msg => "array vs scalar",
    },
    {
        one => [0, 1],
        two => [1, 2],
        out => [1, 2],
        msg => "array vs array",
    },
    {
        one => [0, 1],
        two => {a => 0, b => 1},
        out => {a => 0, b => 1},
        msg => "array vs hash",
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
    {
        one => {a => 0, b => 1},
        two => {a => 9, b => undef},
        out => {a => 9},
        msg => "delete key",
    },
    {
        one => {
            "author" => {
                "givenName" => "John",
                "familyName" => "Doe"
            },
            "content" => "This will be unchanged",
            "tags" => [
                "example",
                "sample"
            ],
            "title" => "Goodbye!",
        },
        two => {
            "author" => {
                "familyName" => undef
            },
            "phoneNumber" => "+01-123-456-7890",
            "tags" => [
                "example"
            ],
            "title" => "Hello!",
        },
        out => {
            "author" => {
                "givenName" => "John"
            },
            "content" => "This will be unchanged",
            "tags" => [
                "example"
            ],
            "phoneNumber" => "+01-123-456-7890",
            "title" => "Hello!",
        },
        msg => "rfc7386 example",
    },
);

for (@tests) {
    $got = merge($_->{one}, $_->{two});
    is_deeply($got, $_->{out}, $_->{msg}) ||
        diag explain $got;
}

done_testing(@tests + 1);

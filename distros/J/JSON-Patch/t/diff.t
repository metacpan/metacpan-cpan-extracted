#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

require Struct::Diff;
use JSON::Patch qw();

my $patch = JSON::Patch::diff(
    Struct::Diff::diff(
        {foo => ['bar']},
        {foo => ['bar', 'baz']}
    )
);
is_deeply(
    $patch,
    [
        {op => 'add', path => '/foo/1', value => 'baz'}
    ],
    'convert from Struct::Diff to JSON::Patch when single arg used'
);

$patch = JSON::Patch::diff(
    {0 => 0, 1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6, 7 => 7, 8 => 8, 9 => 9},
    {0 => 9, 1 => 0, 2 => 1, 3 => 2, 4 => 3, 5 => 4, 6 => 5, 7 => 6, 8 => 7, 9 => 8},
);
is_deeply(
    $patch,
    [
        {
            'op' => 'replace',
            'path' => '/9',
            'value' => 8
        },
        {
            'path' => '/8',
            'value' => 7,
            'op' => 'replace'
        },
        {
            'op' => 'replace',
            'value' => 6,
            'path' => '/7'
        },
        {
            'op' => 'replace',
            'path' => '/6',
            'value' => 5
        },
        {
            'value' => 4,
            'path' => '/5',
            'op' => 'replace'
        },
        {
            'op' => 'replace',
            'value' => 3,
            'path' => '/4'
        },
        {
            'value' => 2,
            'path' => '/3',
            'op' => 'replace'
        },
        {
            'value' => 1,
            'path' => '/2',
            'op' => 'replace'
        },
        {
            'op' => 'replace',
            'value' => 0,
            'path' => '/1'
        },
        {
            'op' => 'replace',
            'path' => '/0',
            'value' => 9
        },
    ],
    "ops for hask keys should be sorted"
);


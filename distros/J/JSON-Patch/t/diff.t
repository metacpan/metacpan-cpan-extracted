#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;

require Struct::Diff;
require JSON::Patch;

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
    ]
);


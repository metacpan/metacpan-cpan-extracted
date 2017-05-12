#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 6;

use List::ToHumanString;

is(
    to_human_string('|list|',),
    '',
    q{Humanize zero items},
);

is(
    to_human_string('|list|', qw/foo/),
    'foo',
    q{Humanize one item},
);

is(
    to_human_string('|list|', qw/foo bar/, undef, ''),
    'foo and bar',
    q{Humanize two items},
);

is(
    to_human_string('|list|', qw/foo bar baz/, undef, ''),
    'foo, bar, and baz',
    q{Humanize three items},
);

is(
    to_human_string('|list|', qw/foo bar/, undef, '', ' ', "\t",
    qw/baz ber/, undef, ''),
    'foo, bar, baz, and ber',
    q{Humanize four items},
);

$List::ToHumanString::Extra_Comma = 0;
is(
    to_human_string('|list|', qw/foo bar/, undef, '', ' ', "\t",
    qw/baz ber/, undef, ''),
    'foo, bar, baz and ber',
    q{Humanize four items; no extra comma},
);

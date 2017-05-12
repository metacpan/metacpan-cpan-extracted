#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 14;

use List::ToHumanString;

is(
    to_human_string('Report{|s}',),
    'Reports',
    q{to_human_string() zero items},
);

is(
    to_human_string('Report{|s}', 1 ),
    'Report',
    q{to_human_string() one item},
);

is(
    to_human_string('Report{|s}', 1, 2),
    'Reports',
    q{to_human_string() two items},
);

is(
    to_human_string('Report{|s}', 1, undef, '', ' '),
    'Report',
    q{to_human_string() 1 item, 1 undef, 1 empty string, 1 blank string},
);

is(
    to_human_string('Report {one|moar} blah', 1 ),
    'Report one blah',
    q{to_human_string() 2 variants, 1 item},
);

is(
    to_human_string('Report {one|moar} blah', 1, 2 ),
    'Report moar blah',
    q{to_human_string() 2 variants, 2 items},
);

is(
    to_human_string('Report {one|moar} blah |list| meow |list|', qw/foo bar/),
    'Report moar blah foo and bar meow foo and bar',
    q{to_human_string() 2 variants, 2 items, with |list|},
);

$List::ToHumanString::Separator = '**SEP**';
is(
    to_human_string('Report {one|moar} {blah**SEP**BER}', 1, 2 ),
    'Report {one|moar} BER',
    q{to_human_string() 2 variants, 2 items, custom separator},
);

is(
    to_human_string('Report {one|moar} {blah**SEP**BER}', 1),
    'Report {one|moar} blah',
    q{to_human_string() 2 variants, 1 item, custom separator},
);

is(
    to_human_string('Report {one|moar} {BER**SEP**}', 1),
    'Report {one|moar} BER',
    q{to_human_string() 1 variant [singular], 1 item, custom separator},
);

is(
    to_human_string('Report {one|moar} {**SEP**BER}', 1),
    'Report {one|moar} ',
    q{to_human_string() 1 variant [plural], 1 item, custom separator},
);

is(
    to_human_string('Report {one|moar} {BER**SEP**}', 1, 2),
    'Report {one|moar} ',
    q{to_human_string() 1 variant [singular], 2 items, custom separator},
);

is(
    to_human_string('Report {one|moar} {**SEP**BER}', 1, 2),
    'Report {one|moar} BER',
    q{to_human_string() 1 variant [plural], 2 items, custom separator},
);

is(
    to_human_string(
        'Report {one|moar} {blah**SEP**BER} '
        . '**SEP**list**SEP** meow **SEP**list**SEP**',
        qw/foo bar/
    ),
    'Report {one|moar} BER foo and bar meow foo and bar',
    q{to_human_string() 2 variants, 2 items, custom separator, and LIST format},
);


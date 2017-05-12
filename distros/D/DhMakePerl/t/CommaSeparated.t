#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
use Test::Differences;

use Debian::Control::Stanza::CommaSeparated;

my $s = Debian::Control::Stanza::CommaSeparated->new('foo bar, "one, two", three');

is_deeply(
    [@$s],
    [ 'foo bar', '"one, two"', 'three' ],
    'constructor parses ok'
);

$s->add("three");

is( scalar(@$s), 3, 'ignores duplicates' );

$s->add('"smith, agent" <asmith@hasyou.yes>, five');

is( scalar(@$s), 5, 'add splits correctly' );

is( $s->[3], '"smith, agent" <asmith@hasyou.yes>', 'add honours quotes' );
is( $s->[4], 'five', 'fifth is five' );

$s->sort;

is_deeply(
    [@$s],
    [   '"one, two"', '"smith, agent" <asmith@hasyou.yes>',
        'five', 'foo bar', 'three',
    ],
    'sort works'
);

is( "$s",
    '"one, two", "smith, agent" <asmith@hasyou.yes>, five, foo bar, three',
    "stringification works"
);

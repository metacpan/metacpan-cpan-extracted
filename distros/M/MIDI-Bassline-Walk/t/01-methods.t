#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'MIDI::Bassline::Walk';

new_ok 'MIDI::Bassline::Walk';

my $obj = new_ok 'MIDI::Bassline::Walk' => [
    verbose => 1,
];
is $obj->verbose, 1, 'verbose';

my $expect = 4;
my $got = $obj->generate('C7b5', $expect);
is scalar(@$got), $expect, 'generate';

done_testing();

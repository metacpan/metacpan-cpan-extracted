#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'MIDI::Bassline::Walk';

my $obj = new_ok 'MIDI::Bassline::Walk' => [
    verbose => 1,
];

is $obj->octave, 2, 'octave';
is $obj->verbose, 1, 'verbose';

my $expect = [qw(-3 -2 -1 1 2 3)];
is_deeply $obj->intervals, $expect, 'intervals';

my $got = $obj->generate('C7b5', 4);
is scalar(@$got), 4, 'generate';

$expect = [qw(41 43 45)]; # C-F note intersection
$got = $obj->generate('C', 4, 'F');
$got = grep { $_ eq $got->[-1] } @$expect;
ok $got, 'intersection';

$obj = new_ok 'MIDI::Bassline::Walk' => [
    verbose => 1,
    tonic   => 1,
];
$expect = [qw(36 40 43)]; # I,III,V of the C2 major scale
$got = $obj->generate('C', 4);
$got = grep { $_ eq $got->[0] } @$expect;
ok $got, 'tonic';

done_testing();

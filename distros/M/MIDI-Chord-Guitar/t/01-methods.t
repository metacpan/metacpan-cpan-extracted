#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'MIDI::Chord::Guitar';

my $mcg = new_ok 'MIDI::Chord::Guitar' => [
    voicing_file => 'share/midi-guitar-chord-voicings.csv',
];

my $got = $mcg->transform('X', '', 0);
my $expect = [60, 64, 67, 72]; # C4
is_deeply $got, $expect, 'transform';

$got = $mcg->transform('C3', 'X', 0);
$expect = [];
is_deeply $got, $expect, 'transform';

$got = $mcg->transform('C3', '', 42);
$expect = [];
is_deeply $got, $expect, 'transform';

$got = $mcg->transform('D3', '', 4);
$expect = [50, 57, 62, 66];
is_deeply $got, $expect, 'transform';

$got = $mcg->transform('E2', '', 3);
$expect = [40, 47, 52, 56, 59, 64];
is_deeply $got, $expect, 'transform';

$got = $mcg->transform('D3', 'dim7', 0);
$expect = [50, 53, 60, 62];
is_deeply $got, $expect, 'transform';

$got = $mcg->transform('D3', 'dim7');
$expect = [ [ 50, 53, 60, 62 ], [ 50, 57, 60, 65, 69 ], [ 50, 57, 60, 65, 69, 74 ], [ 50, 57, 60, 65 ] ];
is_deeply $got, $expect, 'transform';

$got = $mcg->voicings('dim7');
$expect = [ [ 48, 51, 58, 60 ], [ 48, 55, 58, 63, 67 ], [ 48, 55, 58, 63, 67, 72 ], [ 60, 67, 70, 75 ] ];
is_deeply $got, $expect, 'voicings';

$got = $mcg->voicings('dim7', 'ISO');
$expect = [ [ 'C3', 'D#3', 'A#3', 'C4' ], [ 'C3', 'G3', 'A#3', 'D#4', 'G4' ], [ 'C3', 'G3', 'A#3', 'D#4', 'G4', 'C5' ], [ 'C4', 'G4', 'A#4', 'D#5' ] ];
is_deeply $got, $expect, 'voicings';

$got = $mcg->voicings('dim7', 'midi');
$expect = [ [ 'C3', 'Ds3', 'As3', 'C4' ], [ 'C3', 'G3', 'As3', 'Ds4', 'G4' ], [ 'C3', 'G3', 'As3', 'Ds4', 'G4', 'C5' ], [ 'C4', 'G4', 'As4', 'Ds5' ] ];
is_deeply $got, $expect, 'voicings';

$got = $mcg->fingering('D3', '', 1);
$expect = [ 'x13331-5' ];
is_deeply $got, $expect, 'fingering';

$got = $mcg->fingering('D3', '', 4);
$expect = [ 'xx0232-1' ];
is_deeply $got, $expect, 'fingering';

$got = $mcg->fingering('E2', '', 3);
$expect = [ '022100-1' ];
is_deeply $got, $expect, 'fingering';

$got = $mcg->fingering('D3', '', 0);
$expect = [ 'x43121-3' ];
is_deeply $got, $expect, 'fingering';

$got = $mcg->fingering('D3', '');
$expect = [ 'x43121-3', 'x13331-5', '431114-7', '133211-10', 'xx0232-1' ];
is_deeply $got, $expect, 'fingerings';

done_testing();

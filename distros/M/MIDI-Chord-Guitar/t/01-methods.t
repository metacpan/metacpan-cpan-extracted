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
$expect = [41, 47, 50, 56];
is_deeply $got, $expect, 'transform';

$got = $mcg->transform('D3', 'dim7');
$expect = [ [ 41, 47, 50, 56 ], [ 50, 56, 59, 65, 68 ], [ 50, 56, 62, 65, 71, 74 ] ];
is_deeply $got, $expect, 'transform';

$got = $mcg->voicings('dim7');
$expect = [ [ 51, 57, 60, 66 ], [ 48, 54, 57, 63, 66 ], [ 48, 54, 60, 63, 69, 72 ] ];
is_deeply $got, $expect, 'voicings';

$got = $mcg->voicings('dim7', 'ISO');
$expect = [ [ 'D#3', 'A3', 'C4', 'F#4' ], [ 'C3', 'F#3', 'A3', 'D#4', 'F#4' ], [ 'C3', 'F#3', 'C4', 'D#4', 'A4', 'C5' ] ];
is_deeply $got, $expect, 'voicings';

$got = $mcg->voicings('dim7', 'midi');
$expect = [ [ 'Ds3', 'A3', 'C4', 'Fs4' ], [ 'C3', 'Fs3', 'A3', 'Ds4', 'Fs4' ], [ 'C3', 'Fs3', 'C4', 'Ds4', 'A4', 'C5' ] ];
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

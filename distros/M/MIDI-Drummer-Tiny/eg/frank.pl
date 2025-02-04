#!/usr/bin/perl
use strict;
use warnings;

# Basic drum beat of "Frank" by Steve Vai from "The Ultra Zone"

use MIDI::Drummer::Tiny ();

my $d = MIDI::Drummer::Tiny->new(
    file      => $0 . '.mid',
    signature => '3/4',
    bpm       => 114,
    bars      => 2,
    soundfont => '/Users/gene/Music/FluidR3_GM.sf2',
);

my $dura   = $d->quarter;
my $cymbal = $d->closed_hh;

$d->count_in(1);

for my $n (1 .. $d->bars) {
    one();
    two();
    three();
    two();
    one();
    two();
    four();
    two();
}

# $d->write;
# $d->play_with_timidity;
$d->play_with_fluidsynth;

sub one {
    $d->note($dura, $cymbal, $d->kick);
    $d->note($dura, $cymbal) for 1 .. 2;
}

sub two {
    $d->note($dura, $cymbal, $d->snare);
    $d->note($dura, $cymbal) for 1 .. 2;
}

sub three {
    $d->note($dura, $cymbal, $d->kick) for 1 .. 2;
    $d->note($dura, $cymbal);
}

sub four {
    $d->note($dura, $cymbal, $d->kick);
    $d->note($dura, $cymbal);
    $d->note($dura, $cymbal, $d->kick);
}

#!/usr/bin/env perl
use strict;
use warnings;

# Written by Frank Zappa
# Played by Terry Bozzio
# Transcribed by Phillip Albright

# My write-up is at https://ology.github.io/2022/11/13/the-black-page-in-perl/

# use local author libraries
use MIDI::Drummer::Tiny ();
use Music::Duration ();
use MIDI::Util qw(dura_size);

use constant ACCENT => 70;

my $d = MIDI::Drummer::Tiny->new(
    file   => "$0.mid",
    bpm    => 60,
    bars   => 26,
    reverb => 15,
);

Music::Duration::tuplet('hn', 'A', 5);
Music::Duration::tuplet('en', 'B', 5);
Music::Duration::tuplet('qn', 'C', 7);
Music::Duration::tuplet('qn', 'D', 5);
Music::Duration::tuplet('qn', 'E', 11);
Music::Duration::tuplet('qn', 'F', 12);

my $ten = dura_size($d->triplet_eighth);
Music::Duration::add_duration(Gten => $ten * 2);

$d->sync(
    \&pulse,
    \&beat,
);

$d->write;

sub pulse {
    for my $i (1 .. $d->beats * $d->bars) {
        if ($i == 1) {
            $d->flam($d->quarter, 'r', $d->pedal_hh);
        }
        else {
            $d->note($d->quarter, $d->pedal_hh);
        }
    }
}

sub beat {
    # 1
    $d->flam($d->quarter, $d->kick, $d->snare, ACCENT);

    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->eighth, $d->snare);

    $d->note($d->thirtysecond);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->sixteenth, $d->snare);
    $d->note($d->eighth, $d->kick);

    $d->rest($d->sixteenth);
    $d->roll($d->eighth, $d->thirtysecond);
    $d->note($d->sixteenth, $d->kick);

    # 2
    $d->note($d->triplet_sixteenth, $d->kick);
    $d->note($d->triplet_sixteenth, $d->kick);
    $d->note($d->triplet_sixteenth, $d->snare);
    $d->note($d->eighth, $d->kick);

    $d->note($d->triplet_eighth, $d->kick);
    $d->note($d->triplet_sixteenth, $d->kick);
    $d->roll($d->eighth, $d->thirtysecond);

    $d->rest('Ahn');
    $d->flam('Ahn', $d->hi_tom, $d->hi_tom, ACCENT);
    $d->flam('Ahn', $d->hi_mid_tom, $d->hi_mid_tom, ACCENT);
    $d->flam('Ahn', $d->low_tom, $d->low_tom, ACCENT);
    $d->flam('Ahn', $d->low_floor_tom, $d->low_floor_tom, ACCENT);

    # 3
    $d->note($d->dotted_eighth, $d->kick, $d->crash1);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->snare);

    $d->crescendo_roll([100, 50], $d->quarter, $d->thirtysecond);

    $d->crescendo_roll([100, 50], $d->quarter, $d->thirtysecond);

    $d->roll($d->quarter, $d->thirtysecond);

    # 4
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->kick);

    $d->note($d->triplet_sixteenth, $d->snare, $d->crash1);
    $d->note($d->triplet_sixteenth, $d->kick);
    $d->note($d->triplet_sixteenth, $d->kick);
    $d->note('Ben', $d->kick);
    $d->note('Ben', $d->hi_tom);
    $d->note('Ben', $d->hi_tom);
    $d->note('Ben', $d->hi_tom);
    $d->note('Ben', $d->hi_tom);

    $d->note('Cqn', $d->snare, $d->crash1);
    $d->note('Cqn', $d->kick);
    $d->note('Cqn', $d->kick);
    $d->note('Cqn', $d->snare, $d->closed_hh);
    $d->note('Cqn', $d->kick);
    $d->note('Cqn', $d->snare, $d->closed_hh);
    $d->note('Cqn', $d->snare, $d->closed_hh);

    $d->note('Cqn', $d->kick);
    $d->note('Cqn', $d->snare, $d->closed_hh);
    $d->note('Cqn', $d->kick);
    $d->note('Cqn', $d->snare, $d->closed_hh);
    $d->note('Cqn', $d->snare, $d->closed_hh);
    $d->note('Cqn', $d->snare, $d->closed_hh);
    $d->note('Cqn', $d->kick);

    # 5
    $d->rest($d->half);

    $d->note('Cqn', $d->hi_tom);
    $d->note('Cqn', $d->hi_mid_tom);
    $d->note('Cqn', $d->hi_mid_tom);
    $d->note('Cqn', $d->hi_tom);
    $d->note('Cqn', $d->hi_mid_tom);
    $d->note('Cqn', $d->hi_tom);
    $d->note('Cqn', $d->kick);

    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->kick);

    $d->note('Ben', $d->hi_tom);
    $d->note('Ben', $d->hi_tom);
    $d->note('Ben', $d->hi_mid_tom);
    $d->note('Ben', $d->hi_mid_tom);
    $d->note('Ben', $d->low_tom);

    # 6
    $d->note($d->quarter, $d->kick, $d->crash1);

    $d->rest($d->sixteenth);
    $d->note($d->dotted_eighth, $d->hi_mid_tom);

    $d->rest($d->eighth);
    $d->note($d->eighth, $d->hi_mid_tom);

    $d->rest($d->dotted_eighth);
    $d->note($d->sixteenth, $d->low_tom);

    # 7
    $d->rest($d->quarter);

    $d->note($d->quarter, $d->low_tom);

    $d->rest($d->sixteenth);
    $d->note($d->dotted_eighth, $d->low_floor_tom);

    $d->rest($d->eighth);
    $d->note($d->eighth, $d->low_tom);

    # 8 - Repeat the next 10 bars ... in theory
    $d->rest($d->dotted_eighth);
    $d->note($d->sixteenth, $d->low_floor_tom);

    $d->rest($d->quarter);

    $d->note('Cqn', $d->hi_tom);
    $d->note('Cqn', $d->hi_mid_tom);
    $d->note('Cqn', $d->hi_mid_tom);
    $d->note('Cqn', $d->hi_tom);
    $d->note('Cqn', $d->hi_mid_tom);
    $d->note('Cqn', $d->hi_tom);
    $d->note('Cqn', $d->kick);

    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare);

    $d->note('Ben', $d->hi_tom);
    $d->note('Ben', $d->hi_tom);
    $d->note('Ben', $d->hi_tom);
    $d->note('Ben', $d->hi_mid_tom);
    $d->note('Ben', $d->hi_mid_tom);

    # 9
    $d->note($d->sixteenth, $d->kick, $d->crash1);
    $d->roll($d->dotted_eighth, $d->thirtysecond, $d->low_floor_tom);

    $d->roll($d->quarter, $d->thirtysecond, $d->low_floor_tom);

    $d->roll($d->quarter, $d->thirtysecond, $d->low_floor_tom);

    $d->roll($d->quarter, $d->thirtysecond, $d->low_floor_tom);

    # 10
    $d->note($d->quarter, $d->low_floor_tom);

    $d->note($d->eighth, $d->snare);
    $d->rest($d->thirtysecond);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare);

    $d->note($d->triplet_thirtysecond, $d->kick);
    $d->note($d->triplet_thirtysecond, $d->crash1);
    $d->note($d->triplet_sixteenth, $d->snare);
    $d->note($d->triplet_sixteenth, $d->kick);
    $d->note('Ben', $d->hi_mid_tom);
    $d->note('Ben', $d->kick);
    $d->note('Ben', $d->kick);
    $d->note('Ben', $d->snare);
    $d->note('Ben', $d->kick);

    $d->rest('Dqn', $d->snare, $d->snare, ACCENT);
    $d->flam('Dqn');
    $d->flam('Dqn', $d->hi_tom, $d->hi_tom, ACCENT);
    $d->note('Dqn', $d->hi_mid_tom);
    $d->note('Dqn', $d->low_tom);

    # 11
    $d->flam('Dqn', $d->snare, $d->snare, ACCENT);
    $d->flam('Dqn', $d->hi_tom, $d->hi_tom, ACCENT);
    $d->note('Dqn', $d->hi_mid_tom);
    $d->note('Dqn', $d->low_tom);
    $d->note('Dqn', $d->low_floor_tom);

    $d->flam('Dqn', $d->snare, $d->snare, ACCENT);
    $d->flam('Dqn', $d->hi_tom, $d->hi_tom, ACCENT);
    $d->note('Dqn', $d->hi_mid_tom);
    $d->note('Dqn', $d->low_tom);
    $d->note('Dqn', $d->low_floor_tom);

    $d->rest($d->quarter);

    $d->rest($d->quarter);

    # 12
    $d->rest($d->quarter);

    $d->rest($d->quarter);

    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->sixteenth, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);
    $d->note($d->sixteenth, $d->hi_mid_tom);

    $d->note($d->sixteenth, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);
    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);

    # 13
    $d->note($d->thirtysecond, $d->low_tom);
    $d->note($d->thirtysecond, $d->low_tom);
    $d->note($d->thirtysecond, $d->low_floor_tom);
    $d->note($d->thirtysecond, $d->low_floor_tom);
    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);

    $d->note($d->thirtysecond, $d->snare, $d->open_hh);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare, $d->open_hh);
    $d->note($d->thirtysecond, $d->snare, $d->open_hh);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare);

    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->low_tom);
    $d->note($d->thirtysecond, $d->low_tom);

    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->hi_mid_tom);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare, $d->open_hh);

    # 14
    $d->rest($d->eighth);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare, $d->open_hh);

    $d->rest($d->eighth);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare, $d->open_hh);

    $d->rest($d->eighth);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare);

    # 15
    $d->roll('Gten', $d->thirtysecond, $d->snare);
    $d->flam($d->triplet_eighth, $d->hi_tom, $d->hi_tom, ACCENT);

    $d->flam($d->triplet_eighth, $d->hi_mid_tom, $d->hi_mid_tom, ACCENT);
    $d->flam($d->triplet_eighth, $d->hi_tom, $d->hi_tom, ACCENT);
    $d->flam($d->triplet_eighth, $d->low_tom, $d->low_tom, ACCENT);

    $d->note('Dqn', $d->kick);
    $d->note('Dqn', $d->low_floor_tom,);
    $d->note('Dqn', $d->hi_mid_tom);
    $d->note('Dqn', $d->snare, $d->closed_hh);
    $d->note('Dqn', $d->hi_mid_tom);

    $d->note($d->triplet_sixteenth, $d->snare, $d->closed_hh);
    $d->note($d->triplet_sixteenth, $d->kick);
    $d->note($d->triplet_sixteenth, $d->kick);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);

    # 16 (1)
    $d->note($d->quarter, $d->kick, $d->crash1);

    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->eighth, $d->snare);

    $d->rest($d->thirtysecond);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->sixteenth, $d->snare);
    $d->note($d->eighth, $d->kick);

    $d->rest($d->sixteenth);
    $d->roll($d->eighth, $d->thirtysecond, $d->snare);
    $d->note($d->sixteenth, $d->kick);

    # 17 (2)
    $d->note($d->triplet_sixteenth, $d->kick);
    $d->note($d->triplet_sixteenth, $d->kick);
    $d->note($d->triplet_sixteenth, $d->snare);
    $d->note($d->eighth, $d->kick);

    $d->note($d->triplet_eighth, $d->kick);
    $d->note($d->triplet_sixteenth, $d->kick);
    $d->roll($d->eighth, $d->thirtysecond, $d->snare);

    $d->rest('Ahn');
    $d->flam('Ahn', $d->hi_tom, $d->hi_tom, ACCENT);
    $d->flam('Ahn', $d->hi_mid_tom, $d->hi_mid_tom, ACCENT);
    $d->flam('Ahn', $d->low_tom, $d->low_tom, ACCENT);
    $d->flam('Ahn', $d->low_floor_tom, $d->low_floor_tom, ACCENT);

    # 18 (3)
    $d->note($d->dotted_eighth, $d->kick, $d->crash1);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->snare);

    $d->crescendo_roll([100, 50], $d->quarter, $d->thirtysecond);

    $d->crescendo_roll([100, 50], $d->quarter, $d->thirtysecond);

    $d->roll($d->quarter, $d->thirtysecond);

    # 19 (8)
    $d->rest($d->dotted_eighth);
    $d->note($d->sixteenth, $d->low_floor_tom);

    $d->rest($d->quarter);

    $d->note('Cqn', $d->hi_tom);
    $d->note('Cqn', $d->hi_mid_tom);
    $d->note('Cqn', $d->hi_mid_tom);
    $d->note('Cqn', $d->hi_tom);
    $d->note('Cqn', $d->hi_mid_tom);
    $d->note('Cqn', $d->hi_tom);
    $d->note('Cqn', $d->kick);

    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare);

    $d->note('Ben', $d->hi_tom);
    $d->note('Ben', $d->hi_tom);
    $d->note('Ben', $d->hi_tom);
    $d->note('Ben', $d->hi_mid_tom);
    $d->note('Ben', $d->hi_mid_tom);

    # 20 (9)
    $d->note($d->sixteenth, $d->kick, $d->crash1);
    $d->roll($d->dotted_eighth, $d->thirtysecond, $d->low_floor_tom);

    $d->roll($d->quarter, $d->thirtysecond, $d->low_floor_tom);

    $d->roll($d->quarter, $d->thirtysecond, $d->low_floor_tom);

    $d->roll($d->quarter, $d->thirtysecond, $d->low_floor_tom);

    # 21 (10)
    $d->note($d->quarter, $d->low_floor_tom);

    $d->note($d->eighth, $d->snare);
    $d->rest($d->thirtysecond);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare);

    $d->note($d->triplet_thirtysecond, $d->kick);
    $d->note($d->triplet_thirtysecond, $d->crash1);
    $d->note($d->triplet_sixteenth, $d->snare);
    $d->note($d->triplet_sixteenth, $d->kick);
    $d->note('Ben', $d->hi_mid_tom);
    $d->note('Ben', $d->kick);
    $d->note('Ben', $d->kick);
    $d->note('Ben', $d->snare);
    $d->note('Ben', $d->kick);

    $d->rest('Dqn', $d->snare, $d->snare, ACCENT);
    $d->flam('Dqn');
    $d->flam('Dqn', $d->hi_tom, $d->hi_tom, ACCENT);
    $d->note('Dqn', $d->hi_mid_tom);
    $d->note('Dqn', $d->low_tom);

    # 22 (11)
    $d->flam('Dqn', $d->snare, $d->snare, ACCENT);
    $d->flam('Dqn', $d->hi_tom, $d->hi_tom, ACCENT);
    $d->note('Dqn', $d->hi_mid_tom);
    $d->note('Dqn', $d->low_tom);
    $d->note('Dqn', $d->low_floor_tom);

    $d->flam('Dqn', $d->snare, $d->snare, ACCENT);
    $d->flam('Dqn', $d->hi_tom, $d->hi_tom, ACCENT);
    $d->note('Dqn', $d->hi_mid_tom);
    $d->note('Dqn', $d->low_tom);
    $d->note('Dqn', $d->low_floor_tom);

    $d->rest($d->quarter);

    $d->rest($d->quarter);

    # 23
    $d->rest($d->eighth);
    $d->note('Ben', $d->pedal_hh);
    $d->note('Ben', $d->snare);
    $d->note('Ben', $d->snare);
    $d->note('Ben', $d->snare);
    $d->note('Ben', $d->kick);

    $d->note('Ben', $d->snare, $d->closed_hh);
    $d->note('Ben', $d->kick);
    $d->note('Ben', $d->snare, $d->closed_hh);
    $d->note('Ben', $d->snare, $d->closed_hh);
    $d->note('Ben', $d->kick);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->kick);

    $d->note('Ben', $d->snare);
    $d->note('Ben', $d->kick);
    $d->note('Ben', $d->kick);
    $d->note('Ben', $d->snare);
    $d->note('Ben', $d->snare);
    $d->note('Ben', $d->kick);
    $d->note('Ben', $d->kick);
    $d->note('Ben', $d->snare);
    $d->note('Ben', $d->kick);
    $d->note('Ben', $d->snare);

    $d->note('Eqn', $d->snare);
    $d->note('Eqn', $d->kick);
    $d->note('Eqn', $d->kick);
    $d->note('Eqn', $d->snare);
    $d->note('Eqn', $d->snare);
    $d->note('Eqn', $d->kick);
    $d->note('Eqn', $d->snare);
    $d->note('Eqn', $d->snare);
    $d->note('Eqn', $d->kick);
    $d->note('Eqn', $d->snare);
    $d->note('Eqn', $d->kick);

    # 24
    $d->note($d->triplet_half, $d->kick, $d->crash1);
    $d->note($d->triplet_half, $d->snare);
    $d->note($d->triplet_half, $d->snare);

    $d->roll($d->quarter, $d->thirtysecond);

    $d->roll($d->quarter, $d->thirtysecond);

    # 25
    $d->rest($d->thirtysecond);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->snare);
    $d->note($d->thirtysecond, $d->kick);
    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);

    $d->note($d->thirtysecond, $d->hi_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);
    $d->note($d->thirtysecond, $d->hi_mid_tom);
    $d->note($d->thirtysecond, $d->low_tom);
    $d->note($d->thirtysecond, $d->low_tom);
    $d->note($d->thirtysecond, $d->low_floor_tom);
    $d->note($d->thirtysecond, $d->low_floor_tom);
    $d->note($d->thirtysecond, $d->kick);

    $d->note('Eqn', $d->snare);
    $d->note('Eqn', $d->hi_tom);
    $d->note('Eqn', $d->hi_mid_tom);
    $d->note('Eqn', $d->hi_mid_tom);
    $d->note('Eqn', $d->hi_tom);
    $d->note('Eqn', $d->hi_tom);
    $d->note('Eqn', $d->hi_tom);
    $d->note('Eqn', $d->hi_mid_tom);
    $d->note('Eqn', $d->hi_mid_tom);
    $d->note('Eqn', $d->low_tom);
    $d->note('Eqn', $d->low_tom);

    $d->note('Fqn', $d->low_floor_tom);
    $d->note('Fqn', $d->low_floor_tom);
    $d->note('Fqn', $d->low_floor_tom);
    $d->note('Fqn', $d->hi_tom);
    $d->note('Fqn', $d->hi_mid_tom);
    $d->note('Fqn', $d->hi_mid_tom);
    $d->note('Fqn', $d->hi_floor_tom);
    $d->note('Fqn', $d->hi_tom);
    $d->note('Fqn', $d->hi_tom);
    $d->note('Fqn', $d->hi_tom);
    $d->note('Fqn', $d->hi_mid_tom);
    $d->note('Fqn', $d->hi_mid_tom);

    # 26 (9)
    $d->note($d->sixteenth, $d->kick, $d->crash1);
    $d->roll($d->dotted_eighth, $d->thirtysecond, $d->low_floor_tom);

    $d->roll($d->quarter, $d->thirtysecond, $d->low_floor_tom);

    $d->roll($d->quarter, $d->thirtysecond, $d->low_floor_tom);

    $d->roll($d->quarter, $d->thirtysecond, $d->low_floor_tom);
}

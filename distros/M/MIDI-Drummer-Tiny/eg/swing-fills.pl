#!/usr/bin/perl
use strict;
use warnings;

use MIDI::Drummer::Tiny;
use MIDI::Drummer::Tiny::SwingFills;

my $d = MIDI::Drummer::Tiny->new(
    bars      => 16,
    soundfont => '/Users/gene/Music/FluidR3_GM.sf2',
);
my $f = MIDI::Drummer::Tiny::SwingFills->new;

my $every = 4;

for my $i (1 .. $d->bars) {
    my $fill = $f->get_fill($d, $d->ride2);
    if (($i % $every == 0) && ($fill->{dura} == 4)) {
        $fill->{fill}->();
    }
    else {
        $d->note( $d->quarter, $d->ride2, $d->kick );
        if (($i % $every == 0) && ($fill->{dura} == 3)) {
            $fill->{fill}->();
        }
        else {
            $d->note( $d->triplet_eighth, $d->ride2 );
            $d->rest( $d->triplet_eighth );
            $d->note( $d->triplet_eighth, $d->ride2, $d->kick );
            if (($i % $every == 0) && ($fill->{dura} == 2)) {
                $fill->{fill}->();
            }
            else {
                $d->note( $d->quarter, $d->ride2, $d->snare );
                if (($i % $every == 0) && ($fill->{dura} == 1)) {
                    $fill->{fill}->();
                }
                else {
                    $d->note( $d->triplet_eighth, $d->ride2, $d->kick );
                    $d->rest( $d->triplet_eighth );
                    $d->note( $d->triplet_eighth, $d->ride2 );
                }
            }
        }
    }
}

# $d->write;
$d->play_with_timidity;
# $d->play_with_fluidsynth;

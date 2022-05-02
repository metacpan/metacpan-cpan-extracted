#!/usr/bin/env perl
use strict;
use warnings;

# Adapted from the book "Progressive Steps to Syncopation for the Modern Drummer"
# https://www.amazon.com/dp/0882847953

use MIDI::Drummer::Tiny::Syncopate;

my $bpm = shift || 100;

my $d = MIDI::Drummer::Tiny::Syncopate->new(
    bpm    => $bpm,
    file   => "$0.mid",
    kick   => 36,
    snare  => 40,
    reverb => 15,
);

$d->sync(
    \&snare,
    \&kick,
    \&hhat,
);

$d->write;

sub snare {
    $d->combinatorial( $d->snare, {
        count => 1,
        vary  => {
            0 => sub {
                $d->note( $d->sixteenth, $d->snare );
                $d->note( $d->sixteenth, $d->snare );
                $d->note( $d->sixteenth, $d->snare );
                $d->note( $d->sixteenth, $d->snare );
            },
            1 => sub {
                $d->note( $d->eighth, $d->snare );
                $d->note( $d->eighth, $d->snare );
            },
        },
    });
}

sub kick {
    $d->steady( $d->kick );
}

sub hhat {
    $d->steady( $d->closed_hh );
}

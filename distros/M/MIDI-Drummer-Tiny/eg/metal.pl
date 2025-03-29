#!/usr/bin/env perl

# DO NOT just run this without piping the STDOUT to a MIDI file player!
#
# This script is a friendly Unix citizen with default output to STDOUT.
# It does *not* play audio by itself as I don't want to let
# MIDI::Drummer::Tiny create its default "MIDI-Drummer.mid" file.
#
# Play audio through the `timidity` default output like this:
#     metal.pl | timidity --output-mode=d -
#
# If you want a MIDI file, redirect its output like this:
#     metal.pl > metal.mid

use 5.010;
use strict;
use warnings;
use MIDI::Drummer::Tiny;

# default MIDI file output to STDOUT per MIDI::Simple's write_score
my $d = MIDI::Drummer::Tiny->new( file => *STDOUT{IO} );
# my $d = MIDI::Drummer::Tiny->new( soundfont => '/Users/gene/Music/soundfont/FluidR3_GM.sf2' );

# TODO: revise the `file` attribute to accept - as a synonym for STDOUT

$d->count_in(1);    # helps to prime timidity's output

# fairly basic heavy metal drum pattern
my %pattern = (
    $d->closed_hh => [qw( 1000 1000 )],
    $d->open_hh   => [qw( 0000 0100 )],
    $d->pedal_hh  => [qw( 0000 0000 )],
    $d->snare     => [qw( 0010 0010 )],
    $d->kick      => [qw( 1001 1001 )],

    # placeholder crash cymbal voices for the fills to override
    $d->crash1 => [qw( 0000 0000 )],
    $d->crash2 => [qw( 0000 0000 )],

    # TODO: revise add_fill() to not require placeholder voices
);

## no critic (ControlStructures::ProhibitPostfixControls)

$d->sync_patterns( %pattern, duration => $d->eighth )
    for 1 .. $d->bars - 1;    # leave a bar for the fill

$d->add_fill( make_fill(), %pattern );

$d->sync_patterns( %pattern, duration => $d->eighth )
    for 1 .. $d->bars - 1;    # leave a bar for the fill

# override make_fill() with alternative multi-voice patterns
$d->add_fill(
    make_fill( sub {
        my $dr = shift;
        return (
            $dr->snare  => qb(qw( 1110 0010 )),
            $dr->kick   => qb(qw( 0001 1010 )),
            $dr->crash1 => qb(qw( 0000 1000 )),
            $dr->crash2 => qb(qw( 0000 0010 )),
        );
    } ),
    %pattern,
);

# TODO: revise add_fill() to accept array references of beat strings
#       like pattern() and sync_patterns() do, rather than use the
#       qb() function defined below

$d->write;
# $d->play_with_fluidsynth;

# creates a fill that can have individual instruments overridden
# with a code reference
sub make_fill {
    my $override_coderef = shift // sub { };
    return sub {
        my $dr = shift;
        return {
            duration      => 16,
            $dr->pedal_hh => qb(qw( 1000 1000 )),
            $dr->snare    => qb(qw( 1010 1011 )),
            $dr->kick     => qb(qw( 1001 1000 )),
            $dr->crash1   => qb(qw( 0000 0100 )),

            # placeholder cymbals for any overriding fill coderefs
            $dr->closed_hh => qb(qw( 0000 0000 )),
            $dr->open_hh   => qb(qw( 0000 0000 )),
            $dr->crash2    => qb(qw( 0000 0000 )),

            $override_coderef->($dr),
        };
    };
}

# joins an array of (beat)strings into a single string
# useful for add_fill()
sub qb { my @beats = @_; return join q() => @beats }

#!/usr/bin/env perl
use strict;
use warnings;

use if exists $ENV{USER} && $ENV{USER} eq 'gene', lib => map { "$ENV{HOME}/sandbox/$_/lib" } qw(MIDI-RtMidi-ScorePlayer MIDI-Util);

use MIDI::RtMidi::ScorePlayer ();
use MIDI::Util qw( setup_score set_chan_patch );
use Music::Scales qw( get_scale_MIDI );

my $score = setup_score( bpm => 120 );

my %common = ( score => $score );

MIDI::RtMidi::ScorePlayer->new(
  score    => $score,
  parts    => [ \&bass, [ \&treble, \&bass ], [ \&treble, \&bass ], \&bass ],
  common   => \%common,
  sleep    => 0,
  infinite => 0,
)->play;

sub bass {
  my ( %args ) = @_;

  my @pitches = (
    get_scale_MIDI( 'C', 2, 'pentatonic' ),
  );

  my $duration = 'hn'; # half-note
  my $repeats  = 4;    # four of 'em

  $common{'tick.durations'} = [ ($duration) x $repeats ];

  my $bass = sub {
    set_chan_patch( $args{score}, 0, 35 );

    for my $n ( 1 .. $repeats ) {
      my $pitch = $pitches[ int rand @pitches ];
      $args{score}->n( $duration, $pitch );
    }
  };

  return $bass;
}

sub treble {
  my ( %args ) = @_;

  my @pitches = (
    get_scale_MIDI( 'C', 4, 'major' ),
    get_scale_MIDI( 'C', 5, 'major' ),
  );

  my $treble = sub {
    set_chan_patch( $args{score}, 1, 0 );

    for my $n ( 1 .. 4 ) {
      my $pitch = $pitches[ int rand @pitches ];
      $args{score}->n( 'qn', $pitch );
    }
  };

  return $treble;
}

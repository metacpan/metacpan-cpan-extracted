#!/usr/bin/env perl
use strict;
use warnings;

# WORK IN PROGRESS. YMMV.
# Use The Source, Luke.
# Patches welcome!

use IO::Async::Loop ();
use MIDI::Drummer::Tiny ();
use MIDI::RtMidi::ScorePlayer ();
use MIDI::Util qw(dura_size reverse_dump);
use Term::TermKey::Async qw(FORMAT_VIM KEYMOD_CTRL);
use Time::HiRes qw(time);

my $verbose = shift || 0;

my %common;
my @parts;
my ($bpm, $dura, $mode, $repeats) = (100, 'qn', 'parallel', 1);
print "State: BPM=$bpm, Duration=$dura, Mode=$mode, Repeats=$repeats\n";
my $loop = IO::Async::Loop->new;
my $tka  = Term::TermKey::Async->new(
  term   => \*STDIN,
  on_key => sub {
    my ($self, $key) = @_;
    my $pressed = $self->format_key($key, FORMAT_VIM);
    # print "Got key: $pressed\n" if $verbose;
    # HELP
    if ($pressed eq '?') {
      print "State: BPM=$bpm, Duration=$dura, Mode=$mode, Repeats=$repeats\n";
    }
    # PLAY SCORE
    elsif ($pressed eq ' ') {
      print "Play score\n" if $verbose;
      my $d = MIDI::Drummer::Tiny->new(
        bpm  => $bpm,
        file => 'rt-drummer.mid',
      );
      $common{drummer} = $d;
      $common{parts}   = \@parts;
      my $parts = [];
      if ($mode eq 'serial') {
        $parts = [ sub {
          my (%args) = @_;
          return sub { $args{$_}->(%args) for $args{parts}->@* };
        } ];
      }
      elsif ($mode eq 'parallel') {
        my %by_name;
        for my $part (@parts) {
          my ($name) = split /\./, $part;
          push $by_name{$name}->@*, $common{$part};
        }
        for my $part (keys %by_name) {
          my $p = sub {
            my (%args) = @_;
            return sub { $_->(%args) for $by_name{$part}->@* };
          };
          push @$parts, $p;
        }
      }
      MIDI::RtMidi::ScorePlayer->new(
        score    => $d->score,
        common   => \%common,
        parts    => [ $parts ],
        sleep    => 0,
        infinite => 0,
        # dump     => 1,
      )->play;
    }
    # RESET STATE
    elsif ($pressed eq 'r') {
      print "Reset state\n" if $verbose;
      ($bpm, $dura, $mode, $repeats) = (100, 'qn', 'serial', 1);
      %common = ();
      @parts  = ();
    }
    # WRITE SCORE TO FILE
    elsif ($pressed eq 'w') {
      my $file = $common{drummer}->file;
      $common{drummer}->write;
      print "Wrote to $file\n" if $verbose;
    }
    # SERIAL MODE
    elsif ($pressed eq 'm') {
      $mode = 'serial';
      print "Mode: $mode\n" if $verbose;
    }
    # PARALLEL MODE
    elsif ($pressed eq 'M') {
      $mode = 'parallel';
      print "Mode: $mode\n" if $verbose;
    }
    # FASTER
    elsif ($pressed eq 'b') {
      $bpm += 5 if $bpm < 127;
      print "BPM: $bpm\n" if $verbose;
    }
    # SLOWER
    elsif ($pressed eq 'B') {
      $bpm -= 5 if $bpm > 0;
      print "BPM: $bpm\n" if $verbose;
    }
    # ONE REPEAT
    elsif ($pressed eq '!') {
      $repeats = 1;
      print "Repeats: $repeats\n" if $verbose;
    }
    # TWO REPEATS
    elsif ($pressed eq '@') {
      $repeats = 2;
      print "Repeats: $repeats\n" if $verbose;
    }
    # THREE REPEATS
    elsif ($pressed eq '#') {
      $repeats = 3;
      print "Repeats: $repeats\n" if $verbose;
    }
    # FOUR REPEATS
    elsif ($pressed eq '$') {
      $repeats = 4;
      print "Repeats: $repeats\n" if $verbose;
    }
    # FIVE REPEATS
    elsif ($pressed eq '%') {
      $repeats = 5;
      print "Repeats: $repeats\n" if $verbose;
    }
    # SIX REPEATS
    elsif ($pressed eq '^') {
      $repeats = 6;
      print "Repeats: $repeats\n" if $verbose;
    }
    # SEVEN REPEATS
    elsif ($pressed eq '&') {
      $repeats = 7;
      print "Repeats: $repeats\n" if $verbose;
    }
    # EIGHT REPEATS
    elsif ($pressed eq '*') {
      $repeats = 8;
      print "Repeats: $repeats\n" if $verbose;
    }
    # SIXTEENTH
    elsif ($pressed eq '2') {
      $dura = 'sn';
      print "Duration: $dura\n" if $verbose;
    }
    # EIGHTH
    elsif ($pressed eq '3') {
      $dura = 'en';
      print "Duration: $dura\n" if $verbose;
    }
    # QUARTER
    elsif ($pressed eq '4') {
      $dura = 'qn';
      print "Duration: $dura\n" if $verbose;
    }
    # HIHAT
    elsif ($pressed eq 'h') {
      play_patch('hithat', 'closed_hh');
    }
    # HIHAT REST
    elsif ($pressed eq '<Backspace>') { # same key as <C-h>
      rest_patch('hihat');
    }
    # CRASH
    elsif ($pressed eq 'a') {
      play_patch('crash1', 'crash1');
    }
    # CRASH1 REST
    elsif ($pressed eq '<C-a>') {
      rest_patch('crash1');
    }
    elsif ($pressed eq 'q') {
      play_patch('crash2', 'crash1');
    }
    # CRASH2 REST
    elsif ($pressed eq '<C-q>') {
      rest_patch('crash2');
    }
    # KICK
    elsif ($pressed eq 'k') {
      play_patch('kick', 'kick');
    }
    # KICK REST
    elsif ($pressed eq '<C-k>') {
      rest_patch('kick');
    }
    # SNARE
    elsif ($pressed eq 's') {
      play_patch('snare', 'snare');
    }
    # SNARE REST
    elsif ($pressed eq '<C-s>') {
      rest_patch('snare');
    }
    # BASIC BEAT
    elsif ($pressed eq 'x') {
      my $name = 'backbeat';
      print "Basic $name\n" if $verbose;
      my $id = time();
      my $part = sub {
        my (%args) = @_;
        $args{drummer}->note(
          $args{ "$name.duration.$id" },
          $_ % 2 ? $args{drummer}->kick : $args{drummer}->snare
        ) for 1 .. int($args{drummer}->beats / 2) * $common{ "$name.repeats.$id" };
      };
      $common{ "$name.duration.$id" } = $dura;
      $common{ "$name.repeats.$id" } = $repeats;
      $common{ "$name.$id" } = $part;
      push @parts, "$name.$id";
      snippit($part, \%common);
    }
    # BASIC BEAT REST
    elsif ($pressed eq '<C-x>') {
      my $name = 'backbeat';
      print "Basic $name rest\n" if $verbose;
      my $id = time();
      my $part = sub {
        my (%args) = @_;
        my $size = dura_size($args{ "$name.duration.$id" });
        my $x = $size * 2;
        my $twice = reverse_dump('length')->{$x};
        $args{drummer}->rest($twice);
      };
      $common{ "$name.duration.$id" } = $dura;
      $common{ "$name.repeats.$id" } = $repeats;
      $common{ "$name.$id" } = $part;
      push @parts, "$name.$id";
    }
    # DOUBLE KICK BEAT
    elsif ($pressed eq 'X') {
      my $name = 'backbeat';
      print "Double kick $name\n" if $verbose;
      my $id = time();
      my $part = sub {
        my (%args) = @_;
        my $size = dura_size($args{ "$name.duration.$id" });
        my $x = $size / 2;
        my $half = reverse_dump('length')->{$x};
        $args{drummer}->note($half, $args{drummer}->kick);
        $args{drummer}->note($half, $args{drummer}->kick);
        $args{drummer}->note($half, $args{drummer}->snare);
        $args{drummer}->rest($half);
      };
      $common{ "$name.duration.$id" } = $dura;
      $common{ "$name.repeats.$id" } = $repeats;
      $common{ "$name.$id" } = $part;
      push @parts, "$name.$id";
      snippit($part, \%common);
    }
    # FINISH
    $loop->loop_stop if $key->type_is_unicode and
                        $key->utf8 eq "C" and
                        $key->modifiers & KEYMOD_CTRL;
  },
);

$loop->add($tka);
$loop->loop_forever;

sub snippit {
  my ($part, $common) = @_;
  my $d = MIDI::Drummer::Tiny->new(bpm => $bpm);
  $common{drummer} = $d;
  MIDI::RtMidi::ScorePlayer->new(
    score    => $d->score,
    common   => $common,
    parts    => [ $part ],
    sleep    => 0,
    infinite => 0,
  )->play;
}

sub play_patch {
  my ($name, $patch) = @_;
  print ucfirst($name), "\n" if $verbose;
  my $id = time();
  my $part = sub {
    my (%args) = @_;
    $args{drummer}->note(
      $args{ "$name.duration.$id" },
      $args{drummer}->$patch
    ) for 1 .. $common{ "$name.repeats.$id" };
  };
  $common{ "$name.duration.$id" } = $dura;
  $common{ "$name.repeats.$id" } = $repeats;
  $common{ "$name.$id" } = $part;
  push @parts, "$name.$id";
  snippit($part, \%common);
}

sub rest_patch {
  my ($name) = @_;
  print ucfirst($name), " rest\n" if $verbose;
  my $id = time();
  my $part = sub {
    my (%args) = @_;
    $args{drummer}->rest($args{ "$name.duration.$id" })
      for 1 .. $common{ "$name.repeats.$id" };
  };
  $common{ "$name.duration.$id" } = $dura;
  $common{ "$name.repeats.$id" } = $repeats;
  $common{ "$name.$id" } = $part;
  push @parts, "$name.$id";
}

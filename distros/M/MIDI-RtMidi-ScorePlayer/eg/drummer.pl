#!/usr/bin/env perl
use strict;
use warnings;

# WORK IN PROGRESS. YMMV.
# Use The Source, Luke.
# Patches welcome!

use IO::Async::Loop ();
use MIDI::Drummer::Tiny ();
use MIDI::RtMidi::ScorePlayer ();
use Term::TermKey::Async qw(FORMAT_VIM KEYMOD_CTRL);
use Time::HiRes qw(time);

my $verbose = shift || 0;

my %common;
my @parts;
my $bpm  = 100;
my $dura = 'qn';
my $mode = 'serial';
my $loop = IO::Async::Loop->new;
my $tka  = Term::TermKey::Async->new(
  term   => \*STDIN,
  on_key => sub {
    my ($self, $key) = @_;
    my $pressed = $self->format_key($key, FORMAT_VIM);
    # print "Got key: $pressed\n" if $verbose;
    # PLAY SCORE
    if ($pressed eq 'p') {
      print "Play score\n" if $verbose;
      my $d = MIDI::Drummer::Tiny->new(
        bpm  => $bpm,
        file => 'rt-drummer.mid',
      );
      $common{drummer} = $d;
      $common{parts}   = \@parts;
      my $parts;
      if ($mode eq 'serial') {
        $parts = [ sub {
          my (%args) = @_;
          return sub { $args{$_}->(%args) for $args{parts}->@* };
        } ];
      }
      elsif ($mode eq 'parallel') {
        $parts = [];
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
        parts    => $parts,
        sleep    => 0,
        infinite => 0,
      )->play;
    }
    # RESET SCORE
    elsif ($pressed eq 'r') {
      print "Reset score\n" if $verbose;
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
      print "Hihat\n" if $verbose;
      my $id = time();
      my $part = sub {
        my (%args) = @_;
        $args{drummer}->note(
          $args{'hihat.duration.' . $id},
          $args{drummer}->closed_hh
        );
      };
      $common{'hihat.duration.' . $id} = $dura;
      $common{'hihat.' . $id} = $part;
      push @parts, 'hihat.' . $id;
      my $d = MIDI::Drummer::Tiny->new(bpm => $bpm);
      $common{drummer} = $d;
      snippit($part, \%common);
    }
    # KICK
    elsif ($pressed eq 'k') {
      print "Kick\n" if $verbose;
      my $id = time();
      my $part = sub {
        my (%args) = @_;
        $args{drummer}->note(
          $args{'kick.duration.' . $id},
          $args{drummer}->kick
        );
      };
      $common{'kick.duration.' . $id} = $dura;
      $common{'kick.' . $id} = $part;
      push @parts, 'kick.' . $id;
      my $d = MIDI::Drummer::Tiny->new(bpm => $bpm);
      $common{drummer} = $d;
      snippit($part, \%common);
    }
    # SNARE
    elsif ($pressed eq 's') {
      print "Snare\n" if $verbose;
      my $id = time();
      my $part = sub {
        my (%args) = @_;
        $args{drummer}->note(
          $args{'snare.duration.' . $id},
          $args{drummer}->snare
        );
      };
      $common{'snare.duration.' . $id} = $dura;
      $common{'snare.' . $id} = $part;
      push @parts, 'snare.' . $id;
      my $d = MIDI::Drummer::Tiny->new(bpm => $bpm);
      $common{drummer} = $d;
      snippit($part, \%common);
    }
    # BEAT
    elsif ($pressed eq 'x') {
      print "Backbeat\n" if $verbose;
      my $id = time();
      my $part = sub {
        my (%args) = @_;
        $args{drummer}->note(
          $args{'backbeat.duration.' . $id},
          $_ % 2 ? $args{drummer}->kick : $args{drummer}->snare
        ) for 1 .. int($args{drummer}->beats / 2);
      };
      $common{'backbeat.duration.' . $id} = $dura;
      $common{'backbeat.' . $id} = $part;
      push @parts, 'backbeat.' . $id;
      my $d = MIDI::Drummer::Tiny->new(bpm => $bpm);
      $common{drummer} = $d;
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
  MIDI::RtMidi::ScorePlayer->new(
    score  => $common->{drummer}->score,
    common => $common,
    parts  => [ $part ],
    sleep    => 0,
    infinite => 0,
  )->play;
}

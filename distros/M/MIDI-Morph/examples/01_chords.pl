#!/usr/bin/perl

use lib '../lib';
use strict;
use warnings;
use MIDI;
use MIDI::Morph;

my $from = [
    ['note', 0, 182, 1, 60, 100],
    ['note', 0, 182, 1, 62, 70],
    ['note', 0, 182, 1, 67, 100],
    ['note', 0, 182, 1, 72, 120]];

my $to = [
    ['note', 96 * 4, 64, 1, 60, 100],
    ['note', 96 * 4, 64, 1, 65, 120],
    ['note', 96 * 4, 64, 1, 67, 100],
    ['note', 96 * 4, 64, 1, 72, 40]];

my $m = MIDI::Morph->new(
    from => $from,
    to   => $to);

my $score =
  [@$from, @{$m->Morph(0.25)}, @{$m->Morph(0.5)}, @{$m->Morph(0.75)}, @$to];
my $events = MIDI::Score::score_r_to_events_r($score);

my $track = MIDI::Track->new({'events' => $events});
my $opus =
  MIDI::Opus->new({'format' => 0, 'ticks' => 96, 'tracks' => [$track]});
$opus->write_to_file('chord_transition.mid');

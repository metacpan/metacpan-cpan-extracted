#!/usr/bin/env perl
use strict;
use warnings;

use IO::Async::Loop ();
use MIDI::RtMidi::ScorePlayer ();
use MIDI::Util qw(setup_score);
use Music::Scales qw(get_scale_MIDI);
use Term::TermKey::Async qw(FORMAT_VIM KEYMOD_CTRL);

my $loop = IO::Async::Loop->new;
my $tka  = Term::TermKey::Async->new(
  term   => \*STDIN,
  on_key => sub {
    my ($self, $key) = @_;
    # print 'Got key: ', $self->format_key($key, FORMAT_VIM), "\n";

    my $score = setup_score(lead_in => 0, bpm => 120);
    my %common = (score => $score);

    MIDI::RtMidi::ScorePlayer->new(
      score    => $score,
      parts    => [ \&part ],
      common   => \%common,
      sleep    => 0,
      infinite => 0,
    )->play;

    $loop->loop_stop if $key->type_is_unicode and
                        $key->utf8 eq "C" and
                        $key->modifiers & KEYMOD_CTRL;
  },
);

$loop->add($tka);
$loop->loop_forever;

sub part {
  my (%args) = @_;

  my @pitches = (
    get_scale_MIDI('C', 4, 'major'),
    get_scale_MIDI('C', 5, 'major'),
  );

  my $part = sub {
    for my $n (1 .. 3) {
      my $pitch = $pitches[ int rand @pitches ];
      $args{score}->n('sn', $pitch);
    }
  };

  return $part;
}

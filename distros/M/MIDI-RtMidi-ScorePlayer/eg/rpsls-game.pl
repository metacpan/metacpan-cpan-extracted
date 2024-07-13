#!/usr/bin/env perl
use strict;
use warnings;

use Game::RockPaperScissorsLizardSpock qw(rpsls);
use MIDI::RtMidi::ScorePlayer ();
use MIDI::Util qw(setup_score set_chan_patch);
use Music::Scales qw(get_scale_MIDI);

my $choice = shift || die "Usage: perl $0 rock|paper|scissors|lizard|Spock\n";
 
if (my $result = rpsls($choice)) {
    if ($result == 3) {
        print "Its a tie!\n";
    }
    else {
        print "Player $result wins\n";
    }

    my $score = setup_score(lead_in => 0);
    my %common = (score => $score, choice => $choice, result => $result);
    MIDI::RtMidi::ScorePlayer->new(
      score    => $score,
      parts    => [ \&part ],
      common   => \%common,
      sleep    => 0,
      infinite => 0,
    )->play;
}

sub part {
    my (%args) = @_;

    my $octave = $args{result} == 3 ? 2 : 2 + $args{result};
    my @pitches = (
        get_scale_MIDI('C', $octave, 'pentatonic'),
    );

    my $part = sub {
        set_chan_patch($args{score}, 0, 35);

        my $max = $args{result} == 3 ? 3 : 4;
        for my $n (1 .. $max) {
            my $pitch = $pitches[ int rand @pitches ];
            if ($args{result} == 3) {
                $args{score}->n('qn', $pitch);
            }
            else {
                $args{score}->n('en', $pitch);
            }
        }
    };

    return $part;
}

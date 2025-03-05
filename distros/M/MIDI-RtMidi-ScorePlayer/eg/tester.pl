#!/usr/bin/env perl

# I use this code to test control with a system virtual driver...

use strict;
use warnings;

use MIDI::RtMidi::ScorePlayer ();
use MIDI::Util qw(setup_score set_chan_patch);

my $score = setup_score(lead_in => 0);
my %common = (score => $score);
MIDI::RtMidi::ScorePlayer->new(
    score    => $score,
    parts    => [ \&part ],
    common   => \%common,
    sleep    => 0,
    infinite => 1,
    port     => qr/fluid/i,
)->play;

sub part {
    my (%args) = @_;
    my $part = sub {
        for (1 .. 3) {
            $args{score}->n('qn', 'C4');
            $args{score}->n('qn', 'D4');
            $args{score}->n('qn', 'D4');
        }
        $args{score}->n('qn', 'D4');
        $args{score}->n('qn', 'C4');
    };

    return $part;
}

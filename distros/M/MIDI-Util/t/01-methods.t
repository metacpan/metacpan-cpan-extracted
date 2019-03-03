#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'MIDI::Util';

my $score;
lives_ok {
    $score = MIDI::Util::setup_score()
} 'lives through setup_score';
isa_ok $score, 'MIDI::Simple', 'score';

is $score->Tempo, 96, 'Tempo';
is $score->Volume, 120, 'Volume';
is $score->Channel, 0, 'Channel';
is $score->Octave, 4, 'Octave';

lives_ok {
    MIDI::Util::set_chan_patch( $score, 1, 1 )
} 'lives through set_chan_patch';
is $score->Channel, 1, 'Channel';

my $track;
lives_ok {
    $track = MIDI::Util::new_track()
} 'lives through new_track';
isa_ok $track, 'MIDI::Track';

done_testing();

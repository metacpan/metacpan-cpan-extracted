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

is [$score->Score]->[1][0], 'time_signature', 'time signature added';
is [$score->Score]->[1][2], 4, '4 beats';

lives_ok {
    MIDI::Util::set_chan_patch( $score, 1, 1 )
} 'lives through set_chan_patch';
is $score->Channel, 1, 'Channel';

my $x = MIDI::Util::dump('volume');
is $x->[-1], 'fff => 127', 'volume';

$x = MIDI::Util::dump('length');
is $x->[-1], 'ddwn => 7', 'length';

$x = MIDI::Util::dump('ticks');
is $x->[-1], 'ddwn => 672', 'ticks';

$x = MIDI::Util::dump('note');
is $x->[-1], 'B => 11', 'note';

$x = MIDI::Util::dump('note2number');
is $x->[-1], 'G10 => 127', 'note2number';

$x = MIDI::Util::dump('number2note');
is $x->[-1], '127 => G10', 'number2note';

$x = MIDI::Util::dump('patch2number');
is $x->[-1], 'Gunshot => 127', 'patch2number';

$x = MIDI::Util::dump('number2patch');
is $x->[-1], '127 => Gunshot', 'number2patch';

$x = MIDI::Util::dump('notenum2percussion');
is $x->[-1], '81 => Open Triangle', 'notenum2percussion';

$x = MIDI::Util::dump('percussion2notenum');
is $x->[-1], 'Open Triangle => 81', 'percussion2notenum';

$x = MIDI::Util::dump('all_events');
is $x->[-1], 'raw_data', 'all_events';

$x = MIDI::Util::dump('midi_events');
is $x->[-1], 'set_sequence_number', 'midi_events';

$x = MIDI::Util::dump('meta_events');
is $x->[-1], 'raw_data', 'meta_events';

$x = MIDI::Util::dump('text_events');
is $x->[-1], 'text_event_0f', 'text_events';

$x = MIDI::Util::dump('nontext_meta_events');
is $x->[-1], 'raw_data', 'nontext_meta_events';

my @notes = MIDI::Util::midi_format('C','C#','Db','D'); # C, Cs, Df, D
is_deeply \@notes, [qw/C Cs Df D/], 'midi_format';

done_testing();

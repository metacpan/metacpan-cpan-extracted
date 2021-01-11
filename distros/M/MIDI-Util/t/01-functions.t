#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'MIDI::Util', qw(
    midi_dump
    midi_format
    set_chan_patch
    set_time_sig
    setup_score
);

my $score;
lives_ok {
    $score = setup_score()
} 'lives through setup_score';
isa_ok $score, 'MIDI::Simple', 'score';

is $score->Tempo, 96, 'Tempo';
is $score->Volume, 120, 'Volume';
is $score->Channel, 0, 'Channel';
is $score->Octave, 4, 'Octave';

is [$score->Score]->[1][0], 'time_signature', 'time signature added';
is [$score->Score]->[1][2], 4, '4 beats';

lives_ok {
    set_chan_patch( $score, 1, 1 )
} 'lives through set_chan_patch';
is $score->Channel, 1, 'Channel';

my $x = midi_dump('volume');
is $x->[-1], 'fff => 127', 'volume';

$x = midi_dump('length');
is $x->[-1], 'ddwn => 7', 'length';

$x = midi_dump('ticks');
is $x->[-1], 'ddwn => 672', 'ticks';

$x = midi_dump('note');
is $x->[-1], 'B => 11', 'note';

$x = midi_dump('note2number');
is $x->[-1], 'G10 => 127', 'note2number';

$x = midi_dump('number2note');
is $x->[-1], '127 => G10', 'number2note';

$x = midi_dump('patch2number');
is $x->[-1], 'Gunshot => 127', 'patch2number';

$x = midi_dump('number2patch');
is $x->[-1], '127 => Gunshot', 'number2patch';

$x = midi_dump('notenum2percussion');
is $x->[-1], '81 => Open Triangle', 'notenum2percussion';

$x = midi_dump('percussion2notenum');
is $x->[-1], 'Open Triangle => 81', 'percussion2notenum';

$x = midi_dump('all_events');
is $x->[-1], 'raw_data', 'all_events';

$x = midi_dump('midi_events');
is $x->[-1], 'set_sequence_number', 'midi_events';

$x = midi_dump('meta_events');
is $x->[-1], 'raw_data', 'meta_events';

$x = midi_dump('text_events');
is $x->[-1], 'text_event_0f', 'text_events';

$x = midi_dump('nontext_meta_events');
is $x->[-1], 'raw_data', 'nontext_meta_events';

my @notes = midi_format('C','C#','Db','D'); # C, Cs, Df, D
is_deeply \@notes, [qw/C Cs Df D/], 'midi_format';

done_testing();

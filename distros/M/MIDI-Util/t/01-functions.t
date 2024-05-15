#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'MIDI::Util', qw(
    midi_dump
    midi_format
    set_chan_patch
    setup_score
    dura_size
    ticks
    timidity_conf
    get_milliseconds
    score2events
);

my $score;
lives_ok {
    $score = setup_score()
} 'lives through setup_score';
isa_ok $score, 'MIDI::Simple', 'score';

subtest defaults => sub {
    is $score->Tempo, 96, 'Tempo';
    is $score->Volume, 120, 'Volume';
    is $score->Channel, 0, 'Channel';
    is $score->Octave, 4, 'Octave';

    is ticks($score), 96, 'ticks';

    is [$score->Score]->[1][0], 'time_signature', 'time signature added';
    is [$score->Score]->[1][2], 4, '4 beats';
};

subtest setting => sub {
    lives_ok {
        set_chan_patch( $score, 1, 1 )
    } 'lives through set_chan_patch';
    is $score->Channel, 1, 'Channel';
};

subtest dumping => sub {
    my $x = midi_dump('volume');
    is $x->{fff}, 127, 'volume';

    $x = midi_dump('length');
    is $x->{ddwn}, 7, 'length';

    $x = midi_dump('ticks');
    is $x->{ddwn}, 672, 'ticks';

    $x = midi_dump('note');
    is $x->{B}, 11, 'note';

    $x = midi_dump('note2number');
    is $x->{G10}, 127, 'note2number';

    $x = midi_dump('number2note');
    is $x->{127}, 'G10', 'number2note';

    $x = midi_dump('patch2number');
    is $x->{Gunshot}, 127, 'patch2number';

    $x = midi_dump('number2patch');
    is $x->{127}, 'Gunshot', 'number2patch';

    $x = midi_dump('notenum2percussion');
    is $x->{81}, 'Open Triangle', 'notenum2percussion';

    $x = midi_dump('percussion2notenum');
    is $x->{'Open Triangle'}, 81, 'percussion2notenum';

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
};

subtest midi_format => sub {
    my @notes = midi_format('C','C#','Db','D'); # C, Cs, Df, D
    is_deeply \@notes, [qw/C Cs Df D/], 'midi_format';
};

subtest dura_size => sub {
    is dura_size('qn'), 1, 'dura_size';
    is dura_size('wn'), 4, 'dura_size';
    is dura_size('d96'), 1, 'dura_size';
    is dura_size('d384'), 4, 'dura_size';
};

subtest timidity_conf => sub {
    my $sf = 'soundfont.sf2';
    like timidity_conf($sf), qr/$sf$/, 'timidity_conf';
    my $filename = 'timidity_conf';
    timidity_conf($sf, $filename);
    ok -e $filename, 'timidity_conf with filename';
    unlink $filename;
    ok !-e $filename, 'file unlinked';
};

subtest get_milliseconds => sub {
    my $got = get_milliseconds($score);
    is $got, 6250, 'get_milliseconds';
};

subtest score2events => sub {
    my $got = score2events($score);
    is_deeply $got->[3], [ 'note_on', 0, 9, 42, 64 ], 'score2events';
};

done_testing();

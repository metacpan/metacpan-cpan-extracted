#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'MIDI::Ngram';

my $filename = 'eg/twinkle_twinkle.mid';

throws_ok {
    MIDI::Ngram->new
} qr/Missing required arguments: in_file/, 'file required';

throws_ok {
    MIDI::Ngram->new( in_file => $filename )
} qr/Invalid list/, 'invalid in_file';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], ngram_size => 0 )
} qr/Invalid integer/, 'invalid ngram_size';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], max_phrases => -1 )
} qr/Not greater than or equal to zero/, 'invalid max_phrases';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], bpm => 0 )
} qr/Invalid integer/, 'invalid bpm';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], durations => 0 )
} qr/Invalid list/, 'invalid durations';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], patches => 0 )
} qr/Invalid list/, 'invalid patches';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], pause_duration => 0 )
} qr/Invalid duration/, 'invalid pause_duration';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], analyze => 0 )
} qr/Invalid list/, 'invalid analyze';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], loop => 0 )
} qr/Invalid integer/, 'invalid loop';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], weight => 'foo' )
} qr/Invalid Boolean/, 'invalid weight';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], random_patch => 'foo' )
} qr/Invalid Boolean/, 'invalid random_patch';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], shuffle_phrases => 'foo' )
} qr/Invalid Boolean/, 'invalid shuffle_phrases';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], single_phrases => 'foo' )
} qr/Invalid Boolean/, 'invalid single_phrases';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], one_channel => 'foo' )
} qr/Invalid Boolean/, 'invalid one_channel';

my $obj = new_ok 'MIDI::Ngram' => [
    in_file => [$filename],
];

is_deeply $obj->in_file, [$filename], 'in_file';
is $obj->ngram_size, 2, 'ngram_size';
is $obj->max_phrases, 10, 'max_phrases';
is $obj->bpm, 100, 'bpm';
is_deeply $obj->durations, [], 'durations';
is_deeply $obj->patches, [0 .. 127], 'patches';
is $obj->out_file, 'midi-ngram.mid', 'out_file';
ok !$obj->pause_duration, 'pause_duration';
ok !$obj->analyze, 'analyze';
is $obj->loop, 10, 'loop';
ok !$obj->weight, 'weight';
ok !$obj->random_patch, 'random_patch';
ok !$obj->shuffle_phrases, 'shuffle_phrases';
ok !$obj->single_phrases, 'single_phrases';
ok !$obj->one_channel, 'one_channel';
is $obj->score, undef, 'score';
is_deeply $obj->dura, {}, 'notes';
is_deeply $obj->notes, {}, 'notes';

$obj->process;

my $expected = {
    0 => {
        'C4 G4,E3'    => 2,
        'C4,C3 C4'    => 2,
        'D4,F3 D4,G3' => 2,
        'D4,G3 C4,C3' => 2,
        'E4 D4,F3'    => 2,
        'E4 D4,G3'    => 2,
        'E4,C3 E4'    => 2,
        'E4,G3 E4'    => 2,
        'F4 E4,C3'    => 2,
        'G4,E3 G4'    => 4,
    }
};

is_deeply $obj->notes, $expected, 'processed notes';

$expected = {
    0 => {
        'hn,hn qn,hn' => 4,
        'qn hn,hn'    => 4,
        'qn qn,hn'    => 11,
        'qn qn,qn'    => 2,
        'qn,hn qn'    => 16,
        'qn,qn qn,qn' => 2,
    }
};

is_deeply $obj->dura, $expected, 'processed durations';

is_deeply [ sort @{ $obj->_dura_list->{0} } ], ['hn','qn'], '_dura_list';

$expected = {
    'hn,hn qn,hn-qn qn,hn' => 2,
    'qn hn,hn-qn,hn qn'    => 2,
    'qn qn,hn-qn hn,hn'    => 2,
    'qn qn,hn-qn qn,hn'    => 3,
    'qn qn,hn-qn qn,qn'    => 1,
    'qn qn,qn-qn,qn hn,qn' => 1,
    'qn,hn qn-hn,hn qn,hn' => 2,
    'qn,hn qn-qn,hn qn'    => 5,
    'qn,hn qn-qn,qn qn,qn' => 1,
    'qn,qn hn,qn-qn qn,hn' => 1,
};

is_deeply $obj->dura_net->{0}, $expected, 'dura_net';

$expected = {
    'A4 G4,E3-F4,D3 F4'    => 1,
    'A4,F3 A4-G4,E3 F4,D3' => 1,
    'C3 G4,E3-G4 F4,F3'    => 1,
    'C4 G4,E3-G4 A4,F3'    => 1,
    'C4,C3 C4-G4,E3 G4'    => 1,
    'D4,G3 C4,C3-C4 G4,E3' => 1,
    'D4,G3 C4,E3-C3 G4,E3' => 1,
    'E4 D4,F3-D4,G3 C4,E3' => 1,
    'E4 D4,G3-G4,E3 G4'    => 1,
    'E4,C3 E4-D4,F3 D4,G3' => 1,
    'E4,G3 E4-D4,G3 C4,C3' => 1,
    'F4 E4,C3-E4 D4,F3'    => 1,
    'F4 E4,G3-E4 D4,G3'    => 1,
    'F4,D3 F4-E4,C3 E4'    => 1,
    'F4,F3 F4-E4,G3 E4'    => 1,
    'G4 A4,F3-A4 G4,E3'    => 1,
    'G4 F4,F3-F4 E4,G3'    => 1,
    'G4,E3 F4,D3-F4 E4,C3' => 1,
    'G4,E3 G4-A4,F3 A4'    => 1,
    'G4,E3 G4-F4,F3 F4'    => 1,
};

is_deeply $obj->note_net->{0}, $expected, 'note_net';

$obj->populate;

isa_ok $obj->score, 'MIDI::Simple';

is $obj->dura_convert('1920'), 'hn', 'dura_convert';
is $obj->dura_convert('960,1920'), 'qn,hn', 'dura_convert';
is $obj->note_convert('60 61'), 'C4 Cs4', 'note_convert';
is $obj->note_convert('60 61,62'), 'C4 Cs4,D4', 'note_convert';

done_testing();

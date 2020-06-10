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
    MIDI::Ngram->new( in_file => [$filename], min_phrases => 0 )
} qr/Invalid integer/, 'invalid min_phrases';

throws_ok {
    MIDI::Ngram->new( in_file => [$filename], one_channel => 'foo' )
} qr/Invalid Boolean/, 'invalid one_channel';

my $obj = new_ok 'MIDI::Ngram' => [
    in_file => [$filename],
];

is_deeply $obj->in_file, [$filename], 'in_file';
is $obj->ngram_size, 2, 'ngram_size';
is $obj->max_phrases, 0, 'max_phrases';
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
is $obj->min_phrases, 2, 'min_phrases';
ok !$obj->one_channel, 'one_channel';
is $obj->score, undef, 'score';
is_deeply $obj->dura, {}, 'notes';
is_deeply $obj->notes, {}, 'notes';

$obj->process;

my $expected = {
    'A4 A4' => 2,
    'A4 G4' => 2,
    'C4 C4' => 2,
    'C4 G4' => 3,
    'D4 C4' => 3,
    'D4 D4' => 2,
    'E4 D4' => 4,
    'E4 E4' => 4,
    'F4 E4' => 4,
    'F4 F4' => 4,
    'G4 A4' => 2,
    'G4 F4' => 4,
    'G4 G4' => 4,
};

is_deeply $obj->notes->{0}, $expected, 'processed notes';

$expected = {
    'hn qn' => 5,
    'qn hn' => 6,
    'qn qn' => 30,
};

is_deeply $obj->dura->{0}, $expected, 'processed durations';

is_deeply [ sort @{ $obj->_dura_list->{0} } ], ['hn','qn'], '_dura_list';

$expected = {
  'hn*G4 qn*F4' => 2,
  'qn*A4 hn*G4' => 2,
  'qn*A4 qn*A4' => 2,
  'qn*C4 qn*C4' => 2,
  'qn*C4 qn*G4' => 2,
  'qn*D4 hn*C4' => 2,
  'qn*D4 qn*D4' => 2,
  'qn*E4 hn*D4' => 2,
  'qn*E4 qn*D4' => 2,
  'qn*E4 qn*E4' => 4,
  'qn*F4 qn*E4' => 4,
  'qn*F4 qn*F4' => 4,
  'qn*G4 qn*A4' => 2,
  'qn*G4 qn*F4' => 2,
  'qn*G4 qn*G4' => 4,
};

is_deeply $obj->dura_notes->{0}, $expected, 'processed dura_notes';

$expected = {
  'hn qn-qn qn' => 3,
  'qn hn-qn qn' => 2,
  'qn qn-hn qn' => 3,
  'qn qn-qn hn' => 2,
  'qn qn-qn qn' => 9,
};

is_deeply $obj->dura_net->{0}, $expected, 'dura_net';

$expected = {
  'A4 A4-G4 F4' => 2,
  'C4 C4-G4 G4' => 2,
  'F4 E4-E4 D4' => 3,
  'G4 F4-F4 E4' => 3,
  'G4 G4-A4 A4' => 2,
};

is_deeply $obj->note_net->{0}, $expected, 'note_net';

$expected = {
  'hn*G4 qn*F4-qn*F4 qn*E4' => 2,
  'qn*A4 qn*A4-hn*G4 qn*F4' => 2,
  'qn*C4 qn*C4-qn*G4 qn*G4' => 2,
  'qn*F4 qn*E4-qn*E4 qn*D4' => 2,
  'qn*G4 qn*G4-qn*A4 qn*A4' => 2,
};

is_deeply $obj->dura_note_net->{0}, $expected, 'dura_note_net';

$obj->populate;

isa_ok $obj->score, 'MIDI::Simple';

is $obj->_opus_ticks, 480, '_opus_ticks';

is $obj->dura_convert('1920'), 'wn', 'dura_convert';
is $obj->dura_convert('960,1920'), 'hn,wn', 'dura_convert';
is $obj->note_convert('60 61'), 'C4 Cs4', 'note_convert';
is $obj->note_convert('60 61,62'), 'C4 Cs4,D4', 'note_convert';
is $obj->dura_note_convert('1920*60'), 'wn*C4', 'dura_note_convert';
is $obj->dura_note_convert('960,1920*61,62'), 'hn,wn*Cs4,D4', 'dura_note_convert';

done_testing();

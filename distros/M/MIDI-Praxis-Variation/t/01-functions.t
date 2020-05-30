#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok 'MIDI::Praxis::Variation', ':all';
}

my @notes = qw(C5 E5 G5);

my @got = augmentation();
my $expect = [];
is_deeply \@got, $expect, 'augmentation';

@got = augmentation('qn');
$expect = ['d192'];
is_deeply \@got, $expect, 'augmentation';

@got = augmentation('qn', 'qn');
$expect = ['d192', 'd192'];
is_deeply \@got, $expect, 'augmentation';

@got = diminution();
$expect = [];
is_deeply \@got, $expect, 'diminution';

@got = diminution('qn');
$expect = ['d48'];
is_deeply \@got, $expect, 'diminution';

@got = diminution('qn', 'qn');
$expect = ['d48', 'd48'];
is_deeply \@got, $expect, 'diminution';

my $got = dur();
$expect = undef;
is $got, $expect, 'dur';

$got = dur('d96');
$expect = 96;
is $got, $expect, 'dur';

$got = dur('qn');
is $got, $expect, 'dur';

@got = inversion();
$expect = [];
is_deeply \@got, $expect, 'inversion';

@got = inversion('C4', @notes);
$expect = [48, 44, 41];
is_deeply \@got, $expect, 'inversion';

@got = inversion('C5', @notes);
$expect = [60, 56, 53];
is_deeply \@got, $expect, 'inversion';

@got = inversion('D5', @notes);
$expect = [62, 58, 55];
is_deeply \@got, $expect, 'inversion';

$got = note_name_to_number();
$expect = undef;
is $got, $expect, 'note_name_to_number';

$got = note_name_to_number('X');
$expect = -1;
is $got, $expect, 'note_name_to_number';

$got = note_name_to_number('C5');
$expect = 60;
is $got, $expect, 'note_name_to_number';

$got = note2num('C5');
$expect = 60;
is $got, $expect, 'note2num';

@got = ntup();
$expect = [];
is_deeply \@got, $expect, 'ntup';

@got = ntup(0, @notes);
$expect = [];
is_deeply \@got, $expect, 'ntup';

@got = ntup(4, @notes);
$expect = [];
is_deeply \@got, $expect, 'ntup';

@got = ntup(2, @notes);
$expect = [qw(C5 E5 E5 G5)];
is_deeply \@got, $expect, 'ntup';

@got = ntup(3, @notes);
is_deeply \@got, \@notes, 'ntup';

@got = original();
$expect = [];
is_deeply \@got, $expect, 'original';

@got = original(@notes);
$expect = [60, 64, 67];
is_deeply \@got, $expect, 'original';

@got = notes2nums(@notes);
$expect = [60, 64, 67];
is_deeply \@got, $expect, 'notes2nums';

$got = raugmentation();
$expect = undef;
is $got, $expect, 'raugmentation';

$got = raugmentation(0.5, 'd100');
$expect = undef;
is $got, $expect, 'raugmentation';

$got = raugmentation(1.5, 'd100');
$expect = 150;
is $got, $expect, 'raugmentation';

$got = raugmentation(1.5, 'qn');
$expect = 144;
is $got, $expect, 'raugmentation';

$got = raugmentation(2, 'qn');
$expect = 192;
is $got, $expect, 'raugmentation';

$got = raugmentation(1.5, 'qn', 'qn');
$expect = 288;
is $got, $expect, 'raugmentation';

$got = rdiminution();
$expect = undef;
is $got, $expect, 'rdiminution';

$got = rdiminution(0.5, 'd100');
$expect = undef;
is $got, $expect, 'rdiminution';

$got = rdiminution(1.5, 'd100');
$expect = 67;
is $got, $expect, 'rdiminution';

$got = rdiminution(1.5, 'qn');
$expect = 64;
is $got, $expect, 'rdiminution';

$got = rdiminution(2, 'qn');
$expect = 48;
is $got, $expect, 'rdiminution';

$got = rdiminution(1.5, 'qn', 'qn');
$expect = 128;
is $got, $expect, 'rdiminution';

@got = retrograde();
$expect = [];
is_deeply \@got, $expect, 'retrograde';

@got = retrograde(@notes);
$expect = [67, 64, 60];
is_deeply \@got, $expect, 'retrograde';

@got = retrograde_inversion();
$expect = [];
is_deeply \@got, $expect, 'retrograde_inversion';

@got = retrograde_inversion('C4', @notes);
$expect = [48, 51, 55];
is_deeply \@got, $expect, 'retrograde_inversion';

@got = retrograde_inversion('C5', @notes);
$expect = [60, 63, 67];
is_deeply \@got, $expect, 'retrograde_inversion';

@got = retrograde_inversion('D5', @notes);
$expect = [62, 65, 69];
is_deeply \@got, $expect, 'retrograde_inversion';

@got = transposition();
$expect = [];
is_deeply \@got, $expect, 'transposition';

@got = transposition(0, @notes);
$expect = [60, 64, 67];
is_deeply \@got, $expect, 'transposition';

@got = transposition(-12, @notes);
$expect = [48, 52, 55];
is_deeply \@got, $expect, 'transposition';

@got = transposition(12, @notes);
$expect = [72, 76, 79];
is_deeply \@got, $expect, 'transposition';

$got = tye();
$expect = undef;
is $got, $expect, 'tye';

$got = tye('qn');
$expect = 96;
is $got, $expect, 'tye';

$got = tye('qn', 'qn');
$expect = 96 * 2;
is $got, $expect, 'tye';

$got = tie_durations('qn', 'qn');
$expect = 96 * 2;
is $got, $expect, 'tie_durations';

done_testing();

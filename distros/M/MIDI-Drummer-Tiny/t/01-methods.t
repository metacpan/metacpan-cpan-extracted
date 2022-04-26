#!perl

use Test::More;

use_ok 'MIDI::Drummer::Tiny';

my $d = new_ok 'MIDI::Drummer::Tiny';

isa_ok $d->score, 'MIDI::Simple';

is $d->beats, 4, 'beats computed';
is $d->divisions, 4, 'divisions computed';

my @score = $d->score->Score;
is $score[3]->[0], 'time_signature', 'time signature added';
is $score[3]->[2], $d->beats, '4 beats';

$d->note($d->quarter, $d->closed_hh);
@score = $d->score->Score;
is $score[4]->[0], 'note', 'note added';

$d->set_time_sig('5/8');

is $d->beats, 5, 'beats computed';
is $d->divisions, 8, 'divisions computed';

@score = $d->score->Score;
is $score[5]->[0], 'time_signature', 'time signature changed';
is $score[5]->[2], $d->beats, '5 beats';

is $d->counter, 0, 'initial counter';
is $d->counter( $d->counter + 1 ), 1, 'incremented counter';

$d = new_ok 'MIDI::Drummer::Tiny' => [
    beats => 8,
    signature => '5/4',
];

is $d->beats, 8, '8 beats given';
is $d->divisions, 4, '4 divisions default';

@score = $d->score->Score;
is $score[3]->[0], 'time_signature', 'time signature added';
is $score[3]->[2], 5, '5 signature beats';

done_testing();

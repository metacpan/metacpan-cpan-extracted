#!perl

use Test::More;

use_ok 'MIDI::Drummer::Tiny';

my $d = new_ok 'MIDI::Drummer::Tiny';

isa_ok $d->score, 'MIDI::Simple';

is $d->beats, 4, 'beats computed';
is $d->divisions, 4, 'divisions computed';

my @score = $d->score->Score;
is $score[2]->[0], 'time_signature', 'time signature added';
is $score[2]->[2], $d->beats, '4 beats';

$d->note($d->quarter, $d->closed_hh);
@score = $d->score->Score;
is $score[3]->[0], 'note', 'note added';

diag 'Set time signature';
$d->set_time_sig('5/8');

is $d->beats, 5, 'beats computed';
is $d->divisions, 8, 'divisions computed';

@score = $d->score->Score;
is $score[4]->[0], 'time_signature', 'time signature changed';
is $score[4]->[2], $d->beats, '5 beats';

done_testing();

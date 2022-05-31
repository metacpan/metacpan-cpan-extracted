#!perl

use Test::More;

use_ok 'MIDI::Drummer::Tiny';

my $d = new_ok 'MIDI::Drummer::Tiny';

isa_ok $d->score, 'MIDI::Simple';

is $d->beats, 4, 'beats computed';
is $d->divisions, 4, 'divisions computed';

my @score = $d->score->Score;
is $score[3][0], 'time_signature', 'time signature added';
is $score[3][2], $d->beats, '4 beats';

$d->note($d->quarter, $d->closed_hh);
@score = $d->score->Score;
is $score[4][0], 'note', 'note added';

$d->set_time_sig('5/8');

is $d->beats, 5, 'beats computed';
is $d->divisions, 8, 'divisions computed';

@score = $d->score->Score;
is $score[5][0], 'time_signature', 'time signature changed';
is $score[5][2], $d->beats, '5 beats';

is $d->counter, 0, 'initial counter';
is $d->counter( $d->counter + 1 ), 1, 'incremented counter';

$d = new_ok 'MIDI::Drummer::Tiny' => [
    beats => 8,
    signature => '5/4',
];

is $d->beats, 8, '8 beats given';
is $d->divisions, 4, '4 divisions default';

@score = $d->score->Score;
is $score[3][0], 'time_signature', 'time signature added';
is $score[3][2], 5, '5 signature beats';

$d->pattern( instrument => $d->open_hh, patterns => [qw(11111)] );
my $expect = [
    [ 'patch_change', 0, 9, 46 ],
    [ 'note', 0, 96, 9, 46, 100 ], [ 'note', 96, 96, 9, 46, 100 ],
    [ 'note', 192, 96, 9, 46, 100 ], [ 'note', 288, 96, 9, 46, 100 ],
    [ 'note', 384, 96, 9, 46, 100 ]
];
@score = $d->score->Score;
is_deeply [ @score[4 .. 9] ], $expect, 'pattern';

done_testing();

__END__
$d = new_ok 'MIDI::Drummer::Tiny' => [
    verbose => 1
];
for my $n (1 .. 8) {
    $d->add_fill(
        undef,
        $d->open_hh => [ '1' x $n ],
        $d->snare   => [ '0' x $n ],
        $d->kick    => [ '1' x $n ],
    );
}

$d->add_fill(
    undef,
    $d->open_hh => [ '111111111111' ],
    $d->snare   => [ '00000000' ],
    $d->kick    => [ '11111111' ],
);

$d->add_fill(
    undef,
    $d->open_hh => [ '11111111' ],
    $d->snare   => [ '0000' ],
    $d->kick    => [ '1111' ],
);

$d->add_fill(
    sub {
        my $self = shift;
        return {
          duration       => 16,
          $self->open_hh => '00000000',
          $self->snare   => '11111111',
          $self->kick    => '00000000',
        };
    },
    $d->open_hh => [ '11111111' ],
    $d->snare   => [ '0101' ],
    $d->kick    => [ '1010' ],
);

done_testing();

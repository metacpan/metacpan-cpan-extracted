#!perl

use Data::Dumper::Compact qw(ddc);
use Test::More;

use_ok 'MIDI::Drummer::Tiny';

subtest basic => sub {
    my $d = new_ok 'MIDI::Drummer::Tiny';

    isa_ok $d->score, 'MIDI::Simple';

    is $d->beats, 4, 'beats computed';
    is $d->divisions, 4, 'divisions computed';

    is $d->counter, 0, 'initial counter';
    $d->counter( $d->counter + 1 );
    is $d->counter, 1, 'incremented counter';

    my @score = $d->score->Score;
    is $score[3][0], 'time_signature', 'time signature added';
    is $score[3][2], $d->beats, '4 beats';

    $d->note($d->quarter, $d->closed_hh);
    @score = $d->score->Score;
    is $score[4][0], 'note', 'note added';
    is $d->counter, 2, 'incremented counter';

    $d->set_time_sig('5/8');

    is $d->beats, 5, 'beats computed';
    is $d->divisions, 8, 'divisions computed';

    @score = $d->score->Score;
    is $score[5][0], 'time_signature', 'time signature changed';
    is $score[5][2], $d->beats, '5 beats';

    $d = new_ok 'MIDI::Drummer::Tiny' => [
        beats => 8,
        signature => '5/4',
    ];

    is $d->beats, 8, '8 beats given';
    is $d->divisions, 4, '4 divisions default';

    @score = $d->score->Score;
    is $score[3][0], 'time_signature', 'time signature added';
    is $score[3][2], 5, '5 signature beats';

    $expect = 99;
    $d->set_bpm($expect);
    is $d->bpm, $expect, 'set_bpm';
};

subtest pattern => sub {
    my $d = new_ok 'MIDI::Drummer::Tiny';

    $d->pattern( instrument => $d->open_hh, patterns => [qw(11111)] );

    my $expect = [
        [ 'patch_change', 0, 9, 46 ],
        [ 'note',   0, 96, 9, 46, 100 ],
        [ 'note',  96, 96, 9, 46, 100 ],
        [ 'note', 192, 96, 9, 46, 100 ],
        [ 'note', 288, 96, 9, 46, 100 ],
        [ 'note', 384, 96, 9, 46, 100 ],
    ];

    @score = $d->score->Score;

    is_deeply [ @score[4 .. 9] ], $expect, 'pattern';
};

subtest fill => sub {
    my $d = new_ok 'MIDI::Drummer::Tiny' => [
#        verbose => 1
    ];

    $expect = [
        { 35 => ['10000000'], 38 => ['00000111'], 46 => ['10000000'] },
        { 35 => ['10001000'], 38 => ['00000111'], 46 => ['10001000'] },
        { 35 => ['100000001000000000000000'],
          38 => ['000000000000000100100100'],
          46 => ['100000001000000000000000'] },
        { 35 => ['10101000'], 38 => ['00000111'], 46 => ['10101000'] },
        { 35 => ['1000000010000000100000001000000000000000'],
          38 => ['0000000000000000000000000000001000010000'],
          46 => ['1000000010000000100000001000000000000000'] },
        { 35 => ['100010001000100000000000'],
          38 => ['000000000000000100100100'],
          46 => ['100010001000100000000000'] },
        { 35 => ['10000000100000001000000010000000100000000000000000000000'],
          38 => ['00000000000000000000000000000000000000000010000001000000'],
          46 => ['10000000100000001000000010000000100000000000000000000000'] },
        { 35 => ['11111000'], 38 => ['00000111'], 46 => ['11111000'] },
    ];

    for my $n (1 .. 8) {
        my $got = $d->add_fill(
            undef,
            $d->open_hh => [ '1' x $n ], # 46
            $d->snare   => [ '0' x $n ], # 38
            $d->kick    => [ '1' x $n ], # 35
        );
        is_deeply $got, $expect->[$n - 1], "$n note add_fill";
    }

    $expect = { 35 => ['10101000'], 38 => ['00000111'], 46 => ['11111000'] };
    $got = $d->add_fill(
        undef,
        $d->open_hh => [ '11111111' ],
        $d->snare   => [ '0000' ],
        $d->kick    => [ '1111' ],
    );
    is_deeply $got, $expect, 'add_fill';

    $expect = { 35 => ['100100100100100000000000'],
                38 => ['000000000000000100100100'],
                46 => ['101010101010101000000000'] };
    $got = $d->add_fill(
        undef,
        $d->open_hh => [ '111111111111' ],
        $d->snare   => [ '00000000' ],
        $d->kick    => [ '11111111' ],
    );
    is_deeply $got, $expect, 'add_fill';

    $expect = { 35 => ['1000000010000000'], 38 => ['0000100011111111'], 46 => ['1010101000000000'] };
    $got = $d->add_fill(
        sub {
            my $self = shift;
            return {
              duration       => 16,
              $self->open_hh => '00000000',
              $self->snare   => '11111111',
              $self->kick    => '10000000',
            };
        },
        $d->open_hh => [ '11111111' ],
        $d->snare   => [ '0101' ],
        $d->kick    => [ '1010' ],
    );
    is_deeply $got, $expect, 'add_fill';
};

done_testing();

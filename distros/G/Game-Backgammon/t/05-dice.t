#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Backgammon::Dice qw(roll_for opening_for);

sub seed_of { Digest::SHA::sha256($_[0]) }

subtest 'a roll is a pure function of the seed and its number' => sub {
    plan tests => 4;
    my $seed = seed_of('one');
    my @a = map { [ roll_for($seed, $_) ] } 0 .. 49;
    my @b = map { [ roll_for($seed, $_) ] } 0 .. 49;
    is_deeply(\@a, \@b, 'the same inputs give the same roll, always');

    ok(!grep({ $_->[0] < 1 || $_->[0] > 6 || $_->[1] < 1 || $_->[1] > 6 } @a),
       'every face is 1 to 6');
    is(scalar @{ $a[0] }, 2, 'a roll is two faces, so the number indexes a TURN');

    my @other = map { [ roll_for(seed_of('two'), $_) ] } 0 .. 49;
    isnt(join('', map { @$_ } @a), join('', map { @$_ } @other),
         'a different seed is a different game');
};

subtest 'no face is favoured' => sub {
    plan tests => 2;
    my $seed = seed_of('uniform');
    my %n;
    for my $i (0 .. 2999) { $n{$_}++ for roll_for($seed, $i) }
    is(scalar keys %n, 6, 'all six faces appear');
    my @count = sort { $a <=> $b } values %n;
    # 6000 faces over 6 is 1000 each; the truncation is rejected above 252
    # so the only spread should be ordinary sampling noise
    cmp_ok($count[-1] - $count[0], '<', 200,
           "the spread is $count[0] to $count[-1] over 6000 faces");
};

subtest 'the opening roll is really rolled' => sub {
    plan tests => 4;
    my ($first, $dice, $used) = opening_for(seed_of('opening'));
    like($first, qr/\A(?:white|black)\z/, 'somebody goes first');
    isnt($dice->[0], $dice->[1], 'on unequal dice, because a tie is re-rolled');
    cmp_ok($used, '>=', 1, 'and at least one roll number was consumed');

    my ($again) = opening_for(seed_of('opening'));
    is($again, $first, 'and the same seed opens the same way');
};

subtest 'the higher die starts' => sub {
    plan tests => 1;
    # over many seeds, the winner is always the one with the higher die
    my $wrong = 0;
    for my $n (1 .. 200) {
        my ($first, $dice) = opening_for(seed_of("seed-$n"));
        my $expect = $dice->[0] > $dice->[1] ? 'white' : 'black';
        $wrong++ if $first ne $expect;
    }
    is($wrong, 0, 'the higher die goes first, over two hundred openings');
};

subtest 'doubles are four of the same' => sub {
    plan tests => 2;
    my $seed = seed_of('doubles');
    my ($n) = grep { my ($a, $b) = roll_for($seed, $_); $a == $b } 0 .. 200;
    ok(defined $n, 'a doubles roll exists in the first two hundred');
    my @dice = Game::Backgammon::Dice::dice_for($seed, $n);
    is(scalar @dice, 4, 'and it plays four dice, not two');
};

done_testing();

use strict;
use warnings;
use Test::More;

use Game::Senet::Sticks qw(:all);
use Game::Senet::Engine;
my $E = 'Game::Senet::Engine';

my $SEED = 'senet sticks 2026-10-17';
my $N    = 16_000;

subtest 'a throw is four sticks' => sub {
    my $s = throw_for($SEED, 0);
    is(ref $s, 'ARRAY', 'an array reference');
    is(scalar(@$s), 4, 'of four');
    is(scalar(grep { $_ eq '0' || $_ eq '1' } @$s), 4, 'each 0 or 1');
    is_deeply(throw_for($SEED, 0), $s, 'the same seed and number give the same sticks');
    is_deeply(throw_for($SEED, 7), throw_for($SEED, 7), 'every time');
    is(light_of([1, 0, 1, 1]), 3, 'light_of counts the light faces');
    is(light_of([0, 0, 0, 0]), 0, 'none');
    ok(!eval { light_of([1, 0, 1]); 1 }, 'three sticks are not a throw');
    ok(!eval { light_of(3); 1 }, 'nor is a number');
};

subtest 'over sixteen thousand throws' => sub {
    my (@count, @stick, $extra);
    for my $n (0 .. $N - 1) {
        my $s = throw_for($SEED, $n);
        my $throw = light_of($s);
        $count[$throw]++;
        $stick[$_] += $s->[$_] for 0 .. 3;
        $extra += extra_throw(roll_of($throw));
    }

    # THE EXPECTED COUNTS, WRITTEN AS NUMBERS: 16,000 times 1, 4, 6, 4 and 1
    # sixteenths. Four standard deviations of a binomial count beside each.
    my @expected = (1_000, 4_000, 6_000, 4_000, 1_000);
    for my $throw (0 .. 4) {
        my $p = $expected[$throw] / $N;
        my $sd4 = 4 * sqrt($N * $p * (1 - $p));
        cmp_ok(abs(($count[$throw] // 0) - $expected[$throw]), '<', $sd4,
            "a throw of $throw came up $count[$throw] times, within 4 sigma of $expected[$throw]");
    }

    # EACH STICK ON ITS OWN. A count can look right with one stick stuck.
    for my $i (0 .. 3) {
        my $share = $stick[$i] / $N;
        ok($share > 0.49 && $share < 0.51, "stick $i landed light $stick[$i] times in $N");
    }

    cmp_ok(abs($extra - 6_000), '<', 4 * sqrt($N * 0.375 * 0.625),
        "another throw $extra times, within 4 sigma of 6,000: rolls of 1, 4 and 5 are 6 in 16");
};

subtest 'the C table against the sticks, enumerated here' => sub {
    # THE TEST DOES NOT CONTAIN THE TABLE. It counts the sixteen ways four
    # sticks can fall, turns each into a roll with roll_of, and compares.
    my %weight;
    for my $way (0 .. 15) {
        my @sticks = map { ($way >> $_) & 1 } 0 .. 3;
        $weight{ roll_of(light_of(\@sticks)) }++;
    }
    my @c = $E->chances;
    is(scalar(@c), 5, 'five rows');
    is_deeply([ map { $_->[0] } @c ], [ sort { $a <=> $b } keys %weight ],
        'one row a roll, in ascending order of roll');
    for my $row (@c) {
        my ($roll, $w, $d) = @$row;
        is($w, $weight{$roll}, "roll $roll comes up $weight{$roll} ways in sixteen");
        is($d, 16, '  out of 16');
    }
    my $sum = 0;
    $sum += $_->[1] for @c;
    is($sum, 16, 'the weights add to the denominator');
    is(scalar(() = Game::Senet::Engine::_chance(5)), 0, 'chance(5) answers nothing');
    is(scalar(() = Game::Senet::Engine::_chance(-1)), 0, 'nor does chance(-1)');
};

subtest 'extra in C and extra_throw in Perl agree' => sub {
    is($E->extra($_), extra_throw($_), "for a roll of $_") for 1 .. 5;
};

subtest 'a seed is bytes' => sub {
    my $seed = join '', map { chr } 0, 1, 127, 128, 200, 255, (65) x 26;
    is(length($seed), 32, 'a seed of thirty-two bytes, with a NUL and bytes above 127');
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    my $plain = throw_for($seed, 3);
    is("@warn", '', 'gives no warning');
    my $upgraded = $seed;
    utf8::upgrade($upgraded);
    ok(utf8::is_utf8($upgraded), 'the same seed, upgraded');
    is_deeply(throw_for($upgraded, 3), $plain, 'throws the same sticks');
    ok(!eval { throw_for("seed \x{263a}", 0); 1 }, 'a seed holding a character above 255 croaks');
    like($@, qr/a seed is bytes/, 'with a sentence');
    ok(!eval { throw_for('', 0); 1 }, 'an empty seed croaks');
    ok(!eval { throw_for(undef, 0); 1 }, 'and so does none');
    ok(!eval { throw_for($SEED, -1); 1 }, 'a negative throw number croaks');
    ok(!eval { throw_for($SEED, '1.5'); 1 }, 'and so does a fraction');
    ok(!eval { throw_for($SEED); 1 }, 'and so does no number');
};

done_testing();

use strict;
use warnings;
use Test::More;

use Game::RoyalUr::Dice qw(throw_for marked roll_of roll_for opening_for);
use Game::RoyalUr::Engine ();
my $E = 'Game::RoyalUr::Engine';

my $SEED = 'royalur dice 2026-10-09';

my %FINKEL  = (dice => 4, zero_rolls => 0);
my %MASTERS = (dice => 3, zero_rolls => 4);

sub faces { join '', @{ $_[0] } }

subtest 'a throw is that many dice, each marked or not' => sub {
    for my $dice (3, 4) {
        my @bad;
        for my $n (0 .. 499) {
            my $throw = throw_for($SEED, $n, $dice);
            push @bad, "throw $n has " . scalar(@$throw) . ' dice' unless @$throw == $dice;
            push @bad, "throw $n has a face that is neither" if grep { $_ ne '0' && $_ ne '1' } @$throw;
        }
        is("@bad", '', "five hundred throws of $dice dice");
    }
    is(marked([1, 0, 1, 1]), 3, 'marked counts the marked dice');
    is(marked([0, 0, 0, 0]), 0, 'none');
    is(marked([1, 1, 1]),    3, 'and all of three');
};

subtest 'the same seed and number give the same throw, and others do not' => sub {
    is(faces(throw_for($SEED, 7, 4)), faces(throw_for($SEED, 7, 4)), 'asked twice');
    my %by_n    = map { faces(throw_for($SEED, $_, 4)) => 1 } 0 .. 199;
    my %by_seed = map { faces(throw_for("seed $_", 0, 4)) => 1 } 0 .. 199;
    is(scalar(keys %by_n),    16, 'two hundred throw numbers make all sixteen throws');
    is(scalar(keys %by_seed), 16, 'and so do two hundred seeds at one number');
    is(faces(throw_for($SEED, 7, 3)), substr(faces(throw_for($SEED, 7, 4)), 0, 3),
        'three dice are the first three of the four');
};

# THE EXPECTED COUNTS ARE WRITTEN AS NUMBERS. Sixteen thousand throws; a count
# of k marked dice out of four is expected 1000, 4000, 6000, 4000, 1000 times,
# and out of three 2000, 6000, 6000, 2000. Each allowance is four standard
# deviations of a binomial count, rounded up: sqrt(16000 * p * (1 - p)) is 30.6
# for one in sixteen, 41.8 for one in eight, 54.8 for a quarter and 61.2 for
# three in eight.
subtest 'the count of marked dice is binomial' => sub {
    my %want = (
        4 => [ [1000, 123], [4000, 220], [6000, 245], [4000, 220], [1000, 123] ],
        3 => [ [2000, 168], [6000, 245], [6000, 245], [2000, 168] ],
    );
    for my $dice (4, 3) {
        my @count = (0) x ($dice + 1);
        $count[ marked(throw_for($SEED, $_, $dice)) ]++ for 0 .. 15_999;
        for my $k (0 .. $dice) {
            my ($expected, $allowed) = @{ $want{$dice}[$k] };
            cmp_ok(abs($count[$k] - $expected), '<=', $allowed,
                "$dice dice, $k marked: $count[$k] of an expected $expected");
        }
        note("$dice dice over 16,000 throws: @count");
    }
};

# A sum can look right with one die stuck. Each die on its own.
subtest 'each die is fair by itself' => sub {
    my @marked = (0) x 4;
    for my $n (0 .. 15_999) {
        my $throw = throw_for($SEED, $n, 4);
        $marked[$_] += $throw->[$_] for 0 .. 3;
    }
    for my $die (0 .. 3) {
        cmp_ok($marked[$die], '>=', 7840, "die $die is marked at least 49% of the time: $marked[$die]");
        cmp_ok($marked[$die], '<=', 8160, "and at most 51%");
    }
};

# ALL TEN CASES. This is the function "a throw is not a roll" is about.
subtest 'what a count of marked dice is worth' => sub {
    my $nothing = { zero_rolls => 0 };
    my $four    = { zero_rolls => 4 };
    is(roll_of(0, $nothing), 0, 'nothing marked is worth nothing');
    is(roll_of(1, $nothing), 1, 'one is one');
    is(roll_of(2, $nothing), 2, 'two is two');
    is(roll_of(3, $nothing), 3, 'three is three');
    is(roll_of(4, $nothing), 4, 'four is four');
    is(roll_of(0, $four), 4, 'where nothing marked is worth four, it is four');
    is(roll_of(1, $four), 1, 'and one is still one');
    is(roll_of(2, $four), 2, 'two two');
    is(roll_of(3, $four), 3, 'three three');
    is(roll_of(4, $four), 4, 'and four four');
};

subtest 'roll_for is the three in one' => sub {
    my @bad;
    for my $n (0 .. 999) {
        for my $rules (\%FINKEL, \%MASTERS) {
            my $by_hand = roll_of(marked(throw_for($SEED, $n, $rules->{dice})), $rules);
            push @bad, "throw $n" unless roll_for($SEED, $n, $rules) == $by_hand;
        }
    }
    is("@bad", '', 'a thousand throws under each rule set');
    my %masters = map { roll_for($SEED, $_, \%MASTERS) => 1 } 0 .. 999;
    is(join(' ', sort keys %masters), '1 2 3 4', 'three dice with nothing worth four never roll nothing');
    my %finkel = map { roll_for($SEED, $_, \%FINKEL) => 1 } 0 .. 999;
    is(join(' ', sort keys %finkel), '0 1 2 3 4', 'and four dice roll nothing to four');
};

{
    package Local::Rules;
    sub new        { bless { dice => $_[1], zero_rolls => $_[2] }, $_[0] }
    sub dice       { $_[0]{dice} }
    sub zero_rolls { $_[0]{zero_rolls} }
}

subtest 'a rule set is a hash or an object' => sub {
    my $object = Local::Rules->new(3, 4);
    is(roll_of(0, $object), 4, 'an object that answers zero_rolls');
    is(roll_for($SEED, 5, $object), roll_for($SEED, 5, \%MASTERS), 'and dice');
    ok(!eval { roll_of(0, 4); 1 }, 'a bare number is not a rule set');
    ok(!eval { roll_of(0, {}); 1 }, 'nor is a hash with no zero_rolls');
    ok(!eval { roll_of(0, { zero_rolls => 2 }); 1 }, 'nor one where nothing is worth two');
    ok(!eval { roll_for($SEED, 0, { zero_rolls => 0 }); 1 }, 'roll_for wants dice as well');
    ok(!eval { roll_of(5, { zero_rolls => 0 }); 1 }, 'five dice cannot be marked');
};

# THE TABLE IS NOT IN THIS TEST. Every throw the dice can make is walked, each
# is turned into a roll by roll_of, and the weights are counted. The chances
# the engine publishes for a search must be those.
subtest 'the odds the engine publishes are the odds the dice have' => sub {
    for my $dice (3, 4) {
        for my $zero (0, 4) {
            my (%weight, $throws);
            for my $pattern (0 .. 2**$dice - 1) {
                my $count = grep { ($pattern >> $_) & 1 } 0 .. $dice - 1;
                $weight{ roll_of($count, { zero_rolls => $zero }) }++;
                $throws++;
            }
            my $want = join ' ', map { "$_:$weight{$_}/$throws" } sort { $a <=> $b } keys %weight;
            my @chances = $E->chances($dice, $zero);
            my $got = join ' ', map { "$_->[0]:$_->[1]/$_->[2]" } @chances;
            is($got, $want, "$dice dice, nothing marked worth $zero: $want");
            my $sum = 0;
            $sum += $_->[1] for @chances;
            is($sum, $chances[0][2], 'and the weights add up to the denominator');
        }
    }
    is(scalar(() = $E->chances(5, 0)), 0, 'five dice have no chances');
    is(scalar(() = $E->chances(4, 2)), 0, 'nor has nothing marked worth two');
    is(scalar(() = $E->chances(2, 4)), 0, 'nor two dice');
};

# THESE SEEDS WERE FOUND BY LOOKING, on 9 Oct 2026, and what each throws is
# written beside it.
subtest 'the opening throw' => sub {
    my ($first, $used, $throws) = opening_for('opening 3', 4);
    is($first, 'light', '0111 against 0001: light threw three and dark one');
    is($used, 2, 'two throws');
    is(join(' ', map { faces($_) } @$throws), '0111 0001', 'and these are they');
    is(faces($throws->[0]), faces(throw_for('opening 3', 0, 4)), 'light threw throw 0');
    is(faces($throws->[1]), faces(throw_for('opening 3', 1, 4)), 'and dark throw 1');

    ($first, $used, $throws) = opening_for('opening 1', 4);
    is(join(' ', map { faces($_) } @$throws), '1101 1110 0011 1101', 'three each, then two against three');
    is($first, 'dark', 'dark moves first');
    is($used, 4, 'A TIE COSTS TWO MORE THROWS: four, not two');

    ($first, $used, $throws) = opening_for('opening 5', 4);
    is($used, 6, 'two ties cost six');
    is($first, 'light', 'and then light');
};

# In the rule set where nothing marked is worth four steps, nothing marked
# STILL LOSES the opening to one. The count is compared, never the worth.
subtest 'the opening compares what was thrown, not what it would move' => sub {
    my ($first, $used, $throws) = opening_for('opening 8', 3);
    is(join(' ', map { faces($_) } @$throws), '000 010', 'light threw nothing and dark one');
    is($first, 'dark', 'so dark moves first');
    is(roll_of(marked($throws->[0]), \%MASTERS), 4, 'though light throw is worth four');
    is(roll_of(marked($throws->[1]), \%MASTERS), 1, 'and dark one');

    ($first, $used, $throws) = opening_for('opening 22', 3);
    is(join(' ', map { faces($_) } @$throws), '100 000', 'and the other way round');
    is($first, 'light', 'light moves first');
};

subtest 'a seed is bytes' => sub {
    my $seed = "\x00\x01 a seed with a nul and \xff in it";
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $plain = faces(throw_for($seed, 3, 4));
    my $upgraded = $seed;
    utf8::upgrade($upgraded);
    is(faces(throw_for($upgraded, 3, 4)), $plain, 'the same bytes stored the other way give the same throw');
    isnt(faces(throw_for("\x00", 3, 4)) . faces(throw_for("\x00", 4, 4)) . faces(throw_for("\x00", 5, 4)),
         faces(throw_for("\x00\x00", 3, 4)) . faces(throw_for("\x00\x00", 4, 4)) . faces(throw_for("\x00\x00", 5, 4)),
         'a nul is a byte of the seed and not its end');
    is(scalar @warnings, 0, 'and nothing warned');
    ok(!eval { throw_for("a seed with \x{263a} in it", 0, 4); 1 }, 'a character above 255 is not bytes');
};

subtest 'what throw_for refuses' => sub {
    ok(!eval { throw_for(undef, 0, 4); 1 }, 'no seed');
    ok(!eval { throw_for('', 0, 4); 1 }, 'an empty seed');
    ok(!eval { throw_for($SEED, -1, 4); 1 }, 'throw -1');
    ok(!eval { throw_for($SEED, 1.5, 4); 1 }, 'throw one and a half');
    ok(!eval { throw_for($SEED, undef, 4); 1 }, 'no throw number');
    ok(!eval { throw_for($SEED, 0, 2); 1 }, 'two dice');
    ok(!eval { throw_for($SEED, 0, 5); 1 }, 'five dice');
    ok(!eval { throw_for($SEED, 0); 1 }, 'no number of dice');
};

done_testing();

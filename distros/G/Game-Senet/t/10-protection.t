use strict;
use warnings;
use Test::More;
use Time::HiRes ();

use Game::Senet::Engine ':all';
my $E = 'Game::Senet::Engine';

sub t {
    my ($position, $roll, $set) = @_;
    return join ' ', map { $_->trace } $E->new(position => $position)->moves($roll, $set);
}

# PROBLEM 3 OF plan_game_senet/00: protection is the DEFENDER'S run, judged on
# the board before the move. The house the mover leaves is the mover's own.

subtest 'a swap that breaks up the mover\'s own run is allowed' => sub {
    for my $set (qw(kendall skyruk)) {
        is(t('.....lld../........../.......... l 5', 1, $set), '7>8x',
            "$set: 7>8x leaves light's pair 6-7; not 6 (own)");
    }
};

subtest 'a swap INTO the defender\'s run is refused' => sub {
    is(t('.....l.dd./........../.......... l 5', 2, 'kendall'), '6<4',
        'kendall: 6>8 lands in the pair 8-9: refused, so back');
    is(t('.....l.dd./........../.......... l 5', 2, 'skyruk'), '6<4',
        'skyruk: 8 is the lower end of the pair: refused, so back');
    is(t('.....l.dd./........../.......... l 5', 2, { exits => 'kendall', protect => 'none' }), '6>8x',
        'with no protection the same move swaps, so the refusal was the protection');
};

# THE CLAIM OF plan_game_senet/03: when the blockade is 2 or 3, no move swaps an
# inner piece of a run, so protect => 'ends' and protect => 'run' give the same
# lists. By enumeration, in C, over random consistent positions of seven a side.

my $N = 200_000;

for my $blockade (3, 2) {
    my $t0 = Time::HiRes::time();
    my ($compared, $differ) = Game::Senet::Engine::_compare_ends_run($N, 20261017 + $blockade, $blockade);
    my $took = Time::HiRes::time() - $t0;
    is($compared, $N * 5, "blockade $blockade: $N positions, every roll, compared");
    is($differ, 0, "and ends and run gave the same list every time");
    note(sprintf 'blockade %d: %d lists compared in %.2f s', $blockade, $compared, $took);
}

my ($compared, $differ) = Game::Senet::Engine::_compare_ends_run(20_000, 4242, 0);
cmp_ok($differ, '>', 0,
    "with NO blockade they differ ($differ of $compared): the comparison can fail, and the inner-piece clause is live");

done_testing();

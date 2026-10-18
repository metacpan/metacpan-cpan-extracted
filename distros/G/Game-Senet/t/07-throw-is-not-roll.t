use strict;
use warnings;
use Test::More;

use Game::Senet::Sticks qw(:all);
use Game::Senet::Engine;
my $E = 'Game::Senet::Engine';

=pod

A THROW IS NOT A ROLL. This file's only job is to fail when they are confused.

A throw is how many sticks landed light face up, 0 to 4. A roll is what that is
worth in houses, 1 to 5. They agree for 1 to 4 and part at none: a throw of 0
is a roll of 5. Every assertion here would PASS if the two were the same number
from 1 to 4 and FAILS at 0 or 5, so each says something only the difference
can make true.

This is the place such lines go. A later phase that meets the difference (the
generator handed a roll of 5, a facade game whose first throw is 0) appends its
line here, not to a file of its own.

=cut

subtest 'roll_of' => sub {
    is(roll_of(0), 5, 'a throw of 0 is a roll of 5');
    is(roll_of(4), 4, 'a throw of 4 is a roll of 4, so 0 and 4 do not swap');
    ok(!eval { roll_of(5); 1 }, 'roll_of(5) croaks: 5 is never a throw');
    like($@, qr/a throw is a count of light faces, 0 to 4/, 'and says what a throw is');
};

subtest 'extra_throw is asked of a roll' => sub {
    is(extra_throw(5), 1, 'a roll of 5 throws again');
    ok(!eval { extra_throw(0); 1 }, 'extra_throw(0) croaks: 0 is never a roll');
    like($@, qr/a roll is a number of houses, 1 to 5/, 'and says what a roll is');
    is(join(', ', map { extra_throw(roll_of($_)) } 0 .. 4), '1, 1, 0, 0, 1',
        'for the throws 0 to 4 in order, another throw is 1, 1, 0, 0, 1');
};

subtest 'the C table is in order of roll' => sub {
    my %w = map { $_->[0] => $_->[1] } $E->chances;
    is($w{5}, 1, 'roll 5 has weight 1: it is the throw of nothing');
    is($w{1}, 4, 'roll 1 has weight 4');
    ok(!exists $w{0}, 'and there is no roll 0');
    is($E->extra(0), -1, 'extra(0) is not a roll');
    is($E->extra(6), -1, 'nor is extra(6)');
    is($E->extra(5), 1, 'and extra(5) throws again');
};

subtest 'a seed whose first throw is nothing' => sub {
    my $seed = 'senet throw of nothing 11';
    is(light_of(throw_for($seed, 0)), 0, "'$seed' throws no light face at throw 0");
    is(roll_for($seed, 0), 5, 'which is a roll of 5');
    is(extra_throw(roll_for($seed, 0)), 1, 'and another throw');
};

subtest 'phase 03: the generator is handed a ROLL' => sub {
    my $bd = $E->new(position => 'l........./........../.......... l 5');
    ok(!eval { $bd->moves(0, 'kendall'); 1 }, 'a roll of 0 is refused: it is a throw');
    is(join(' ', map { $_->trace } $bd->moves(5, 'kendall')), '1>6', 'a roll of 5 moves a piece five houses');
};

done_testing();

#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Mahjong;

plan tests => 6;

subtest 'the first hand' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'deal-1');
	is($g->hand_no, 1, 'hand 1');
	is($g->dealer, 0, 'seat 0 deals hand 1');
	is($g->prevailing, 0, 'the east round');
	is($g->round, 1, 'round 1');
	is($g->phase, 'discard', 'the dealer is to discard');
	is($g->turn, 0, 'and it is seat 0');
	is_deeply([ $g->waiting_on ], [ 0 ], 'waited on: the dealer');
	is($g->hand_of(0)->total, 14, 'the dealer holds fourteen');
	is($g->hand_of($_)->total, 13, "seat $_ holds thirteen") for 1 .. 3;
	is_deeply([ map { $g->seat_wind($_) } 0 .. 3 ], [ 0, 1, 2, 3 ], 'east south west north from the dealer');
	my @out = $g->take_outcomes;
	is($out[0]{kind}, 'deal', 'the first outcome is the deal');
	is($out[0]{dealer}, 0, 'naming the dealer');
	is_deeply($out[0]{winds}, [ 0, 1, 2, 3 ], 'and the winds');
	ok(!grep({ $_->{kind} eq 'deal' && grep { /tile|hand/ } grep { $_ ne 'hand' } keys %$_ } @out), 'the deal carries no tiles');
	is_deeply([ $g->take_outcomes ], [], 'taken means cleared');
	is_deeply([ $g->check_invariants ], [], 'the invariants hold');
};

subtest 'flowers in the deal are replaced dealer first' => sub {
	# find a seed whose deal puts a flower in somebody's hand: the seeds are
	# tried in order, so the one found is the one found every run
	my ($g, @out);
	for my $n (1 .. 200) {
		my $try = Game::Mahjong::Rules->new(seed => "flower-$n");
		my @o = $try->take_outcomes;
		if (grep { $_->{kind} eq 'flower' } @o) { ($g, @out) = ($try, @o); last }
	}
	ok($g, 'a seed with a flower in the deal') or return;
	my @flowers = grep { $_->{kind} eq 'flower' } @out;
	my @draws = grep { $_->{kind} eq 'drew' } @out;
	is(scalar @draws, scalar @flowers, 'one replacement from the back for every flower');
	ok(!grep({ $_->{from} ne 'back' } @draws), 'all from the back');
	is($g->hand_of($g->dealer)->total, 14, 'the dealer still holds fourteen');
	is($g->hand_of($_)->total, 13, "seat $_ still holds thirteen") for grep { $_ != $g->dealer } 0 .. 3;
	# the order: every flower of an earlier seat (counterclockwise from the
	# dealer) is replaced before a later seat's
	my @order = map { ($g->dealer + $_) % 4 } 0 .. 3;
	my %rank = map { $order[$_] => $_ } 0 .. 3;
	my $last = -1;
	my $ordered = 1;
	for my $d (@draws) { $ordered = 0 if $rank{ $d->{seat} } < $last; $last = $rank{ $d->{seat} } }
	ok($ordered, 'replacements run dealer first, then counterclockwise');
	is(scalar(map { @{ $g->hand_of($_)->flowers } } 0 .. 3), scalar @flowers, 'every flower is exposed');
	is_deeply([ $g->check_invariants ], [], 'the invariants hold');
};

subtest 'the deal is a function of the seed and the hand number' => sub {
	my $a = Game::Mahjong::Rules->new(seed => 'same');
	my $b = Game::Mahjong::Rules->new(seed => 'same');
	is($a->to_string, $b->to_string, 'the same seed deals the same hands');
	my $c = Game::Mahjong::Rules->new(seed => 'same', hand_no => 2);
	isnt($c->to_string, $a->to_string, 'hand 2 differs');
	is($c->dealer, 1, 'and seat 1 deals it');
	my $d = Game::Mahjong::Rules->new(seed => 'same', hand_no => 5);
	is($d->prevailing, 1, 'hand 5 is the south round');
	is($d->dealer, 0, 'dealt by seat 0 again');
	is_deeply([ map { $d->seat_wind($_) } 0 .. 3 ], [ 0, 1, 2, 3 ], 'seat winds from the dealer');
	my $e = Game::Mahjong::Rules->new(seed => 'same', hand_no => 16);
	is($e->prevailing, 3, 'hand 16 is the north round');
	is($e->dealer, 3, 'dealt by seat 3');
	is($e->seat_wind(3), 0, 'who is east');
	is($e->seat_wind(0), 1, 'and seat 0 is south');
};

subtest 'a written position' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'w', position => {
		hands => [ '123m 456p 789s 222s 55m', '19m 19p 19s ESWN RGB', '11p 33p 55p 77p 99p EE S', '147m 258p 369s ESW N' ],
		wall  => [qw(m5 p6 f1 s2)],
		turn  => 0,
	});
	is($g->phase, 'discard', 'discard phase');
	is($g->turn, 0, 'seat 0 on turn');
	is($g->hand_of(0)->total, 14, 'fourteen');
	is($g->wall->remaining, 4, 'the written wall');
	is_deeply([ $g->take_outcomes ], [], 'a written position emits no deal');
	ok(!eval { Game::Mahjong::Rules->new(seed => 'w', position => { hands => [ '123m', '19m', '11p', '147m' ], wall => [] }); 1 },
		'wrong sizes die');
	ok(!eval { Game::Mahjong::Rules->new(seed => 'w', position => { hands => [ '1m' ], wall => [] }); 1 }, 'not four hands dies');
};

subtest 'what new refuses' => sub {
	ok(!eval { Game::Mahjong::Rules->new(seed => ''); 1 }, 'an empty seed');
	ok(!eval { Game::Mahjong::Rules->new(seed => 'x', hand_no => 17); 1 }, 'hand 17');
	ok(!eval { Game::Mahjong::Rules->new(seed => 'x', hand_no => 0); 1 }, 'hand 0');
	ok(!eval { Game::Mahjong::Rules->new(seed => 'x', totals => [ 0, 0 ]); 1 }, 'two totals');
};

# THE MUTATION CHECKS, named so they can be run by hand:
#   deal the dealer thirteen                          -> 'the dealer holds fourteen' fails
#   replace flowers from the front                    -> 'all from the back' fails
#   dealer = hand_no % 4                              -> 'seat 0 deals hand 1' fails
subtest 'the mutation checks are written down' => sub {
	pass('see the comment above this subtest');
};

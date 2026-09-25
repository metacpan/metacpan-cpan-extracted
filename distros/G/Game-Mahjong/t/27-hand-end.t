#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Mahjong;
use Play;

sub id { return Game::Mahjong::Tiles::id_of($_[0]) }

my $RUBBISH = '19m 19p 19s ESWN RGB';
my $DULL = '2m 3m 7m 8m 9m 2p 3p 4p 6p 7p 8p 2s 3s';

# a position where the dealer wins at once on the fourteen it holds
sub winning_position {
	my ($hand_no) = @_;
	my $dealer = ($hand_no - 1) % 4;
	my @hands = ($RUBBISH) x 4;
	$hands[$dealer] = '123m 456p 789s 222s 55m';
	return Game::Mahjong::Rules->new(seed => "end-$hand_no", hand_no => $hand_no,
		position => { hands => \@hands, wall => [qw(p6)], turn => $dealer, drawn => 'm5' });
}

plan tests => 6;

subtest 'the settlement lands on the totals' => sub {
	my $g = winning_position(1);
	is_deeply([ $g->check_invariants ], [], 'the written table is sound');
	ok($g->apply(0, { kind => 'win' }), 'the dealer wins');
	my ($end) = grep { $_->{kind} eq 'hand_end' } $g->take_outcomes;
	my $p = $end->{points};
	is_deeply($g->totals, [ 3 * (8 + $p), -(8 + $p), -(8 + $p), -(8 + $p) ], 'self-drawn: everybody gives eight plus the points');
	is_deeply($end->{totals}, $g->totals, 'the record carries the totals');
	is($end->{hand}, 1, 'hand 1');
	is(scalar @{ $g->history }, 1, 'one hand in the history');
	my $sum = 0; $sum += $_ for @{ $g->totals };
	is($sum, 0, 'zero-sum');
};

subtest 'the deal passes whatever happened' => sub {
	my $g = winning_position(1);
	$g->apply(0, { kind => 'win' });
	is($g->hand_no, 2, 'a win: hand 2');
	is($g->dealer, 1, 'the deal passed to seat 1');

	my $dry = Game::Mahjong::Rules->new(seed => 'dry', hand_no => 3, position => { hands => [ $RUBBISH, $RUBBISH, '19m 19p 19s ESWN RGB 5m', $RUBBISH ], wall => [], turn => 2 });
	$dry->apply(2, { kind => 'discard', tile => id('m5') });
	is($dry->hand_no, 4, 'a drawn hand: hand 4');
	is($dry->dealer, 3, 'the deal passed to seat 3');

	# the dealer, seat 3 in hand 4, discards into seat 0's eight-point hand:
	# 123m 456m 999p 999s EE is a double pung, two pungs of terminals, a
	# short straight, concealed and a closed wait
	my $lost = Game::Mahjong::Rules->new(seed => 'lost', hand_no => 4, position => {
		hands => [ '123m 46m 999p 999s EE', $DULL, $DULL, '5m 5m 5m 9m 1p 3p 7p 2s 4s 6s 8s W N R' ],
		wall => [qw(p6)], turn => 3,
	});
	is_deeply([ $lost->check_invariants ], [], 'the written table is sound');
	$lost->apply(3, { kind => 'discard', tile => id('m5') });
	is($lost->phase, 'claim', 'seat 0 is asked');
	ok($lost->apply(0, { kind => 'win' }), 'seat 0 wins off the dealer, seat 3');
	is($lost->hand_no, 5, 'the dealer lost: hand 5 all the same');
	is($lost->dealer, 0, 'the deal passed to seat 0');
	is($lost->prevailing, 1, 'and the south round begins');
};

subtest 'the prevailing wind turns every four hands' => sub {
	for my $case ([ 4, 0 ], [ 5, 1 ], [ 8, 1 ], [ 9, 2 ], [ 12, 2 ], [ 13, 3 ], [ 16, 3 ]) {
		my ($hand, $wind) = @$case;
		my $g = Game::Mahjong::Rules->new(seed => 'wind', hand_no => $hand);
		is($g->prevailing, $wind, "hand $hand: prevailing $wind");
		is($g->dealer, ($hand - 1) % 4, 'the dealer by hand number');
	}
};

subtest 'the sixteenth hand ends the game' => sub {
	my $g = winning_position(16);
	ok($g->apply(3, { kind => 'win' }), 'seat 3 wins hand 16');
	is($g->status, 'finished', 'finished');
	is($g->phase, 'finished', 'the phase says so');
	is_deeply([ $g->waiting_on ], [], 'nobody is waited on');
	is($g->winner, 3, 'seat 3 won the game');
	is($g->result, 'score', 'on score');
	my @out = $g->take_outcomes;
	my ($end) = grep { $_->{kind} eq 'game_end' } @out;
	ok($end, 'a game_end outcome');
	is($end->{winner}, 3, 'naming the winner');
	is_deeply($end->{places}, Game::Mahjong::Result::places($g->totals), 'and the places');
	is($g->apply(3, { kind => 'discard', tile => id('m1') })->code, 'game_over', 'nothing more is taken');
	is_deeply([ $g->legal(3) ], [], 'and nothing is legal');
};

subtest 'a level game is a draw' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'level', hand_no => 16, position => { hands => [ ($RUBBISH) x 3, '19m 19p 19s ESWN RGB 5m' ], wall => [], turn => 3 });
	$g->apply(3, { kind => 'discard', tile => id('m5') });
	is($g->status, 'finished', 'finished on exhaustion');
	is($g->winner, undef, 'no winner');
	is($g->result, 'draw', 'a draw');
	is_deeply($g->totals, [ 0, 0, 0, 0 ], 'all level');
};

subtest 'a whole game of sixteen hands, driven' => sub {
	my ($g, $bad, $census) = Play::play_game(seed => 'whole-game', default => Play::eager_chooser(Play::new_rng('whole-game')), check => 1);
	is_deeply($bad, [], 'no invariant broke') or diag join "\n", @$bad;
	is($g->status, 'finished', 'finished');
	is($census->{hands}, 16, 'sixteen hands');
	my $sum = 0; $sum += $_ for @{ $g->totals };
	is($sum, 0, 'zero-sum at the end');
	ok((grep { $_->{kind} eq 'game_end' } @{ $census->{events} }), 'a game_end');
	cmp_ok($census->{moves}, '>', 16 * 20, 'more than twenty moves a hand');
	diag sprintf 'moves %d, discards %d, answers %d, claims %d, kongs %d, wins %d', @{$census}{qw(moves discards answers claims kongs wins)};
};

#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Mahjong;

sub id { return Game::Mahjong::Tiles::id_of($_[0]) }

my $RUBBISH = '19m 19p 19s ESWN RGB';
# rubbish with no honour and nothing that runs with a five of characters
my $DULL = '2m 3m 7m 8m 9m 2p 3p 4p 6p 7p 8p 2s 3s';
# seat 0 with an exposed pung of fives and the fourth in hand: fourteen
my $PROMOTER = '5m 123p 11s 88s 7m 6p 8p pung(555m)';

plan tests => 5;

subtest 'a promoted kong that nobody can rob' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'promote', position => { hands => [ $PROMOTER, $DULL, $DULL, $DULL ], wall => [qw(p5 s6 m9)], turn => 0 });
	is_deeply([ $g->check_invariants ], [], 'the written table is sound');
	my ($kong) = grep { $_->{kind} eq 'kong' } $g->legal(0);
	ok($kong && $kong->{tile} == id('m5'), 'the promotion is offered');
	ok($g->apply(0, { kind => 'kong', tile => id('m5') }), 'declared');
	is($g->phase, 'discard', 'nobody could rob: performed at once');
	is($g->hand_of(0)->melds->[0]->kind, 'kong', 'the pung is a kong');
	ok($g->hand_of(0)->melds->[0]->promoted, 'promoted');
	is($g->hand_of(0)->count(id('m5')), 0, 'the fourth five left the hand');
	is($g->drawn_from, 'back', 'a replacement from the back');
	is($g->replacement, 'kong', 'after a kong');
	is_deeply([ map { $_->{kind} } $g->take_outcomes ], [qw(kong drew)], 'a kong and a draw');
	is_deeply([ $g->check_invariants ], [], 'the invariants hold');
};

subtest 'robbing the kong' => sub {
	# seat 2 waits on the five with 4-6: 456m 999p 999s RRR 11m is a double
	# pung, two pungs of terminals, a dragon pung, concealed and a closed
	# wait: nine points
	my @hands = ( $PROMOTER, $DULL, '46m 999p 999s RRR 11m', $DULL );
	my $g = Game::Mahjong::Rules->new(seed => 'rob', position => { hands => \@hands, wall => [qw(p5 s6 m9)], turn => 0 });
	is_deeply([ $g->check_invariants ], [], 'the written table is sound');
	ok($g->apply(0, { kind => 'kong', tile => id('m5') }), 'seat 0 promotes');
	is($g->phase, 'rob', 'a rob window');
	is_deeply([ $g->waiting_on ], [ 2 ], 'seat 2 is asked');
	is_deeply($g->window->{may}{2}, ['win'], 'to win, and nothing else');
	is(join(' ', map { $_->{kind} } $g->legal(2)), 'pass win', 'pass or win');
	is($g->hand_of(0)->melds->[0]->kind, 'pung', 'the pung is still a pung while the window is open');
	ok($g->apply(2, { kind => 'win' }), 'seat 2 robs it');
	my @out = $g->take_outcomes;
	my ($end) = grep { $_->{kind} eq 'hand_end' } @out;
	ok($end, 'the hand ended');
	is($end->{winner}, 2, 'seat 2 won');
	is($end->{by}, 'rob', 'by robbing the kong');
	is($end->{from}, 0, 'off seat 0');
	ok((grep { $_->{key} eq 'robbing_the_kong' } @{ $end->{fans} }), 'robbing the kong among the fans');
	is($end->{deltas}[0], -(8 + $end->{points}), 'the konger gives as a discarder');

	my $h = Game::Mahjong::Rules->new(seed => 'rob-pass', position => { hands => \@hands, wall => [qw(p5 s6 m9)], turn => 0 });
	$h->apply(0, { kind => 'kong', tile => id('m5') });
	ok($h->apply(2, { kind => 'pass' }), 'or passes');
	is($h->phase, 'discard', 'the kong stands');
	is($h->hand_of(0)->melds->[0]->kind, 'kong', 'promoted');
	is($h->hand_of(0)->count(id('m5')), 0, 'the fourth five left the hand');
	is($h->drawn_from, 'back', 'and the replacement came');
	is_deeply([ $h->check_invariants ], [], 'the invariants hold');
};

subtest 'no kong in the turn a chow or pung was claimed' => sub {
	my @hands = ( '5m 5m 5m 9m 1p 3p 6p 2s 4s 6s 8s W N R', '46m 7777p 19s ES RGB', $RUBBISH, $RUBBISH );
	my $g = Game::Mahjong::Rules->new(seed => 'after-chow', position => { hands => \@hands, wall => [qw(p5 s6 m9)], turn => 0 });
	is_deeply([ $g->check_invariants ], [], 'the written table is sound');
	$g->apply(0, { kind => 'discard', tile => id('m5') });
	ok($g->apply(1, { kind => 'chow', tiles => [ id('m4'), id('m6') ] }), 'seat 1 chows');
	ok(!grep({ $_->{kind} eq 'kong' } $g->legal(1)), 'no kong of the four sevens offered this turn');
	is($g->apply(1, { kind => 'kong', tile => id('p7') })->code, 'no_kong', 'refused');
	ok($g->apply(1, { kind => 'discard', tile => id('s1') }), 'seat 1 discards instead');
};

subtest 'a concealed kong then a win on the replacement' => sub {
	# kong the fives; the back of the wall is the 1 of dots, which pairs
	my @hands = ( '5555m 456p 789s 111s 1p', $DULL, $DULL, $DULL );
	my $g = Game::Mahjong::Rules->new(seed => 'kong-win', position => { hands => \@hands, wall => [qw(p5 s6 p1)], turn => 0 });
	is_deeply([ $g->check_invariants ], [], 'the written table is sound');
	ok($g->apply(0, { kind => 'kong', tile => id('m5') }), 'kong');
	is($g->drawn, id('p1'), 'the replacement is the 1 of dots');
	my ($win) = grep { $_->{kind} eq 'win' } $g->legal(0);
	ok($win, 'a win is offered');
	ok($g->apply(0, { kind => 'win' }), 'taken');
	my ($end) = grep { $_->{kind} eq 'hand_end' } $g->take_outcomes;
	ok((grep { $_->{key} eq 'out_with_replacement_tile' } @{ $end->{fans} }), 'out with replacement tile among the fans');
	ok((grep { $_->{key} eq 'concealed_kong' } @{ $end->{fans} }), 'and the concealed kong');
	ok(!grep({ $_->{key} eq 'self_drawn' } @{ $end->{fans} }), 'not also self-drawn: fully concealed implies it');
};

# THE MUTATION CHECKS, named so they can be run by hand:
#   perform the promotion before the rob window     -> 'the pung is still a pung while the window is open' fails
#   allow a kong after a chow                       -> 'no kong of the four sevens' fails
#   mark a flower replacement as 'kong'             -> t/24 'a win now would be on a flower replacement' fails
subtest 'the mutation checks are written down' => sub {
	pass('see the comment above this subtest');
};

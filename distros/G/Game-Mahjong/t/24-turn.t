#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Mahjong;

sub id { return Game::Mahjong::Tiles::id_of($_[0]) }
sub kinds_of { return [ map { Game::Mahjong::Tiles::code_of($_) } @_ ] }

# a quiet table: nobody can claim anything seat 0 discards, so a discard
# is followed at once by seat 1's draw
my @QUIET = ( '123m 456p 789s 222s 5m 8m', '19m 19p 19s ESWN RG B', '11p 33p 55p 77p 99p EE S', '147m 258p 369s ESW N' );

sub quiet { my (%o) = @_; return Game::Mahjong::Rules->new(seed => 'turn', position => { hands => [ @QUIET ], wall => [qw(p6 s2 m9 f1 p2)], turn => 0, %o }) }

plan tests => 8;

subtest 'a discard, and the draw that follows' => sub {
	my $g = quiet();
	my @legal = $g->legal(0);
	is(scalar(grep { $_->{kind} eq 'discard' } @legal), 12, 'twelve distinct kinds to discard');
	ok(!grep({ $_->{kind} eq 'kong' } @legal), 'no kong');
	ok(!grep({ $_->{kind} eq 'win' } @legal), 'no win: the hand is not complete');
	my $r = $g->apply(0, { kind => 'discard', tile => id('m8') });
	ok($r && !ref $r, 'the discard is taken');
	is_deeply(kinds_of(@{ $g->pool_of(0) }), ['m8'], 'the pool holds it');
	is($g->hand_of(0)->count(id('m8')), 0, 'the hand does not');
	is($g->phase, 'discard', 'nobody could claim: straight to the next turn');
	is($g->turn, 1, 'seat 1');
	is($g->hand_of(1)->total, 14, 'seat 1 drew');
	is($g->drawn, id('p6'), 'the front of the wall');
	is($g->drawn_from, 'wall', 'from the wall');
	is($g->wall->remaining, 4, 'four left');
	my @out = $g->take_outcomes;
	is_deeply([ map { $_->{kind} } @out ], [qw(discard drew)], 'a discard and a draw');
	is($out[0]{actor}, 0, 'the discard is seat 0\'s');
	is($out[1]{actor}, 'sys', 'the draw is the engine\'s');
	ok(!exists $out[1]{tile}, 'and carries no tile');
	is_deeply([ $g->check_invariants ], [], 'the invariants hold');
};

subtest 'what a discard refuses' => sub {
	my $g = quiet();
	my $r = $g->apply(0, { kind => 'discard', tile => id('we') });
	is($r->code, 'tile_not_held', 'a tile not held');
	ok(scalar @{ $r->legal }, 'with the legal moves attached');
	is($g->apply(1, { kind => 'discard', tile => id('m1') })->code, 'not_your_turn', 'not on turn');
	is($g->apply(0, { kind => 'pass' })->code, 'wrong_phase', 'a pass with no window');
	is($g->apply(0, { kind => 'pung' })->code, 'wrong_phase', 'a pung with no window');
	is($g->apply(0, { kind => 'bogus' })->code, 'bad_move', 'a move it does not know');
	is($g->apply(0, 'discard')->code, 'bad_move', 'not a hash');
	is($g->apply(0, { kind => 'discard', tile => 99 })->code, 'bad_move', 'a kind off the table');
	is($g->apply(0, { kind => 'discard' })->code, 'bad_move', 'no tile');
	is($g->apply(7, { kind => 'discard', tile => 1 })->code, 'bad_move', 'no such seat');
	is($g->phase, 'discard', 'nothing moved');
	is($g->turn, 0, 'still seat 0');
};

subtest 'a concealed kong and its replacement from the back' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'kong', position => {
		hands => [ '5555m 456p 789s 222s 8p', @QUIET[1 .. 3] ],
		wall  => [qw(p6 s2 m9 f1 p2)], turn => 0,
	});
	my @legal = $g->legal(0);
	my ($kong) = grep { $_->{kind} eq 'kong' } @legal;
	ok($kong, 'a kong is offered');
	is($kong->{tile}, id('m5'), 'of the fives');
	ok($g->apply(0, { kind => 'kong', tile => id('m5') }), 'declared');
	is($g->hand_of(0)->meld_count, 1, 'one meld');
	ok($g->hand_of(0)->melds->[0]->concealed, 'concealed');
	is($g->drawn, id('p2'), 'the replacement is the back of the wall');
	is($g->drawn_from, 'back', 'from the back');
	is($g->replacement, 'kong', 'after a kong');
	is($g->turn, 0, 'still on turn');
	is($g->hand_of(0)->total, 14, 'fourteen');
	my @out = $g->take_outcomes;
	is_deeply([ map { $_->{kind} } @out ], [qw(kong drew)], 'a kong and a draw');
	is($out[0]{how}, 'concealed', 'how');
	ok($g->apply(0, { kind => 'kong', tile => id('m5') })->code eq 'tile_not_held', 'a second kong of fives: none held');
	is_deeply([ $g->check_invariants ], [], 'the invariants hold');
};

subtest 'a flower on a replacement is replaced again' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'flower', position => {
		hands => [ '5555m 456p 789s 222s 8p', @QUIET[1 .. 3] ],
		wall  => [qw(p6 s2 m9 p2 f1)], turn => 0,
	});
	ok($g->apply(0, { kind => 'kong', tile => id('m5') }), 'kong');
	is_deeply([ map { $_->{kind} } $g->take_outcomes ], [qw(kong drew flower drew)], 'the back was a flower: exposed, drawn again');
	is_deeply(kinds_of(@{ $g->hand_of(0)->flowers }), ['f1'], 'the flower exposed');
	is($g->drawn, id('p2'), 'then the next from the back');
	is($g->replacement, 'flower', 'a win now would be on a flower replacement, not a kong one');
	is($g->wall->remaining, 3, 'three left');
};

subtest 'a self-drawn win, and its refusals' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'win', position => {
		hands => [ '123m 456p 789s 222s 55m', @QUIET[1 .. 3] ], wall => [qw(p6)], turn => 0, drawn => 'm5',
	});
	my ($win) = grep { $_->{kind} eq 'win' } $g->legal(0);
	ok($win, 'a win is offered: mixed straight 8 and more');
	ok($g->apply(0, { kind => 'win' }), 'taken');
	my @out = $g->take_outcomes;
	my ($end) = grep { $_->{kind} eq 'hand_end' } @out;
	ok($end, 'the hand ended');
	is($end->{winner}, 0, 'seat 0 won');
	is($end->{by}, 'self', 'self-drawn');
	ok((grep { $_->{key} eq 'fully_concealed_hand' } @{ $end->{fans} }), 'fully concealed among the fans');
	cmp_ok($end->{points}, '>=', 8, 'at least eight');
	is($end->{deltas}[0], 3 * (8 + $end->{points}), 'the winner takes three times eight plus the points');
	is($g->hand_no, 2, 'hand 2 dealt');
	is($g->dealer, 1, 'by seat 1');

	my $seven = Game::Mahjong::Rules->new(seed => 'seven', position => {
		hands => [ '234m 567p 456s 888s 33m', @QUIET[1 .. 3] ], wall => [qw(p6)], turn => 0, drawn => 'm3',
	});
	ok(!grep({ $_->{kind} eq 'win' } $seven->legal(0)), 'seven points: no win offered');
	is($seven->apply(0, { kind => 'win' })->code, 'too_few_points', 'and refused as too few points');
	my $none = quiet();
	is($none->apply(0, { kind => 'win' })->code, 'not_a_win', 'an incomplete hand is not a win');
};

subtest 'the wall runs out' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'dry', position => { hands => [ @QUIET ], wall => [], turn => 0 });
	ok($g->apply(0, { kind => 'discard', tile => id('m8') }), 'the discard');
	my @out = $g->take_outcomes;
	my ($end) = grep { $_->{kind} eq 'hand_end' } @out;
	ok($end, 'nobody could claim and nobody could draw: the hand ended');
	is($end->{by}, 'exhausted', 'exhausted');
	is($end->{winner}, undef, 'no winner');
	is_deeply($end->{deltas}, [ 0, 0, 0, 0 ], 'nothing moves');
	is_deeply($g->totals, [ 0, 0, 0, 0 ], 'totals unchanged');
	is($g->hand_no, 2, 'hand 2 dealt from the seed');
	is($g->hand_of($g->dealer)->total, 14, 'a new deal');
	is_deeply([ $g->check_invariants ], [], 'the invariants hold');
};

subtest 'the last tile of the wall is drawable and its discard is marked' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'last', position => { hands => [ @QUIET ], wall => [qw(m2)], turn => 0 });
	ok($g->apply(0, { kind => 'discard', tile => id('m8') }), 'seat 0 discards');
	is($g->turn, 1, 'seat 1 drew the last tile');
	ok($g->last_draw_emptied, 'and the engine knows it was the last');
	ok($g->wall->is_empty, 'the wall is empty');
	ok($g->apply(1, { kind => 'discard', tile => id('m2') }), 'seat 1 discards it');
	my @out = $g->take_outcomes;
	ok((grep { $_->{kind} eq 'hand_end' && $_->{by} eq 'exhausted' } @out), 'nobody claims, nobody can draw: exhausted');
};

# THE MUTATION CHECKS, named so they can be run by hand:
#   draw from the back after a discard                -> 'the front of the wall' fails
#   allow a win at seven                              -> 'refused as too few points' fails
#   replace a kong from the front                     -> 'the replacement is the back' fails
subtest 'the mutation checks are written down' => sub {
	pass('see the comment above this subtest');
};

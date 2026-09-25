#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Mahjong;

sub id { return Game::Mahjong::Tiles::id_of($_[0]) }
sub kinds { return join ' ', map { $_->{kind} } @_ }

# THE TABLE. Seat 0 discards the 5 of characters. Seat 1 (next) can chow it
# with 4-6; seat 2 holds a pair of fives and can pung; seat 3 waits on it
# with 4-6 of its own (not next, so no chow): 456m 999p 999s GGG 11m is a
# double pung (2), two pungs of terminals (2), a dragon pung (2), concealed
# (2) and a closed wait (1), nine points, over the eight. Every kind is held
# at most four times across the four hands and the wall, which the
# invariants check: three fives (one, two, none), four nines of dots, four
# green dragons.
my @HANDS = (
	'5m 2m 8m 9m 1p 3p 7p 2s 4s 6s 8s W N R',   # seat 0: fourteen, one five to discard
	'46m 19p 19s ESWN RGB',                     # seat 1: the chow shape and rubbish
	'55m 1p 3p 7p 2s 4s 6s 8s E S W N',         # seat 2: a pair of fives
	'46m 999p 999s GGG 11m',                    # seat 3: waiting on the five
);
my $RUBBISH = '19m 19p 19s ESWN RGB';
# rubbish with no honour and nothing that runs with a five of characters
my $DULL = '2m 3m 7m 8m 9m 2p 3p 4p 6p 7p 8p 2s 3s';

sub table {
	my (%o) = @_;
	return Game::Mahjong::Rules->new(seed => 'claims', position => { hands => [ @HANDS ], wall => [qw(p6 s2 m9 p2 s3 s7)], turn => 0, %o });
}

plan tests => 10;

subtest 'the window opens on the seats that can claim' => sub {
	my $g = table();
	is_deeply([ $g->check_invariants ], [], 'the written table is sound');
	is($g->hand_of(0)->total, 14, 'seat 0 holds fourteen');
	is($g->hand_of($_)->total, 13, "seat $_ holds thirteen") for 1 .. 3;
	ok($g->apply(0, { kind => 'discard', tile => id('m5') }), 'seat 0 discards the 5');
	is($g->phase, 'claim', 'a window');
	is($g->turn, undef, 'nobody is on turn');
	my $w = $g->window;
	is($w->{tile}, id('m5'), 'on the 5');
	is($w->{from}, 0, 'from seat 0');
	is_deeply([ sort keys %{ $w->{may} } ], [ 1, 2, 3 ], 'three seats asked');
	is_deeply($w->{may}{1}, ['chow'], 'seat 1 may chow');
	is_deeply($w->{may}{2}, ['pung'], 'seat 2 may pung');
	is_deeply($w->{may}{3}, ['win'], 'seat 3 may win');
	is_deeply([ $g->waiting_on ], [ 1, 2, 3 ], 'all three waited on, from the seat after the discarder');
	is(kinds($g->legal(1)), 'pass chow', 'seat 1: pass or chow');
	is(kinds($g->legal(2)), 'pass pung', 'seat 2: pass or pung');
	is(kinds($g->legal(3)), 'pass win', 'seat 3: pass or win');
	is_deeply([ $g->legal(0) ], [], 'the discarder has nothing');
	is_deeply([ $g->check_invariants ], [], 'the invariants hold');
};

subtest 'a pung makes the chow moot; the win is still waited on' => sub {
	my $g = table();
	$g->apply(0, { kind => 'discard', tile => id('m5') });
	$g->take_outcomes;
	ok($g->apply(2, { kind => 'pung' }), 'seat 2 pungs');
	is_deeply([ $g->waiting_on ], [ 3 ], 'only seat 3 is waited on now: seat 1\'s chow cannot beat a pung');
	is($g->phase, 'claim', 'the window is still open for the win');
	is($g->apply(1, { kind => 'chow', tiles => [ id('m4'), id('m6') ] })->code, 'cannot_claim', 'the moot seat cannot chow');
	ok($g->apply(1, { kind => 'pass' }), 'but may pass');
	ok($g->apply(3, { kind => 'pass' }), 'seat 3 passes');
	is($g->phase, 'discard', 'the window closed');
	is($g->turn, 2, 'seat 2 is on turn with the pung');
	is($g->hand_of(2)->meld_count, 1, 'a meld');
	is($g->hand_of(2)->melds->[0]->kind, 'pung', 'a pung');
	is($g->hand_of(2)->melds->[0]->claimed_from, 0, 'from seat 0');
	is($g->hand_of(2)->total, 14, 'holding fourteen');
	ok($g->claimed_this_turn, 'and may not kong this turn');
	is_deeply([ @{ $g->pool_of(0) } ], [], 'the tile left the pool');
	my @out = $g->take_outcomes;
	is_deeply([ map { $_->{kind} } @out ], [qw(pung pass pass claimed)], 'the answers, then the claim');
	is($out[-1]{meld}, 'pung', 'claimed as a pung');
	ok(!grep({ $_->{kind} eq 'drew' } @out), 'nobody drew');
	is_deeply([ $g->check_invariants ], [], 'the invariants hold');
};

subtest 'a win closes the window at once when nobody nearer could win' => sub {
	my $g = table();
	$g->apply(0, { kind => 'discard', tile => id('m5') });
	$g->take_outcomes;
	ok($g->apply(3, { kind => 'win' }), 'seat 3 wins');
	my @out = $g->take_outcomes;
	my ($end) = grep { $_->{kind} eq 'hand_end' } @out;
	ok($end, 'the hand ended without waiting for seats 1 and 2');
	is($end->{winner}, 3, 'seat 3 won');
	is($end->{by}, 'discard', 'by discard');
	is($end->{from}, 0, 'off seat 0');
	is($end->{deltas}[0], -(8 + $end->{points}), 'the discarder gives eight plus the points');
	is($end->{deltas}[1], -8, 'the others give eight');
	is($g->hand_no, 2, 'hand 2');
};

subtest 'the chow closes the window when nothing else could be claimed' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'chow', position => {
		hands => [ $HANDS[0], $HANDS[1], $RUBBISH, $RUBBISH ], wall => [qw(p6 s2)], turn => 0,
	});
	is_deeply([ $g->check_invariants ], [], 'the written table is sound');
	$g->apply(0, { kind => 'discard', tile => id('m5') });
	is_deeply([ sort keys %{ $g->window->{may} } ], [ 1 ], 'only seat 1 is asked');
	my @shapes = grep { $_->{kind} eq 'chow' } $g->legal(1);
	is(scalar @shapes, 1, 'one chow shape');
	is_deeply($shapes[0]{tiles}, [ id('m4'), id('m6') ], '4-6');
	is($g->apply(1, { kind => 'chow', tiles => [ id('m4'), id('m4') ] })->code, 'not_a_meld', 'a shape it does not hold');
	is($g->apply(1, { kind => 'chow', tiles => [ id('m6') ] })->code, 'bad_move', 'one tile');
	ok($g->apply(1, { kind => 'chow', tiles => [ id('m6'), id('m4') ] }), 'the chow, tiles in either order');
	is($g->phase, 'discard', 'closed at once');
	is($g->turn, 1, 'seat 1 on turn');
	is($g->hand_of(1)->melds->[0]->to_notation, 'chow(456m)', 'the chow');
	ok(!grep({ $_->{kind} eq 'kong' } $g->legal(1)), 'no kong this turn');
	is($g->apply(1, { kind => 'kong', tile => id('m1') })->code, 'no_kong', 'and a kong is refused as no_kong');
};

subtest 'only the next seat may chow' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'wrong', position => {
		hands => [ $HANDS[0], $RUBBISH, $HANDS[1], $RUBBISH ], wall => [qw(p6 s2)], turn => 0,
	});
	$g->apply(0, { kind => 'discard', tile => id('m5') });
	is($g->phase, 'discard', 'no window: seat 2 could chow but is not next');
	is($g->turn, 1, 'seat 1 drew');
	for my $from (0 .. 3) {
		my @hands = ($DULL) x 4;
		$hands[$from] = '5m 5m 5m 9m 1p 3p 7p 2s 4s 6s 8s W N R';
		$hands[ ($from + 1) % 4 ] = '46m 19p 19s ESWN RGB';
		my $t = Game::Mahjong::Rules->new(seed => "around-$from", position => { hands => \@hands, wall => [qw(p6 s2)], turn => $from });
		$t->apply($from, { kind => 'discard', tile => id('m5') });
		is($t->phase, 'claim', "seat $from discards: the seat after it is asked");
		is_deeply([ keys %{ $t->window->{may} } ], [ ($from + 1) % 4 ], 'and only it');
	}
};

subtest 'two seats could win: the nearer one is waited on, and wins the tie' => sub {
	# seats 1 and 3 both wait on the five with 4-6: seat 1 with 999p 999s
	# RRR 11m, seat 3 with 111p 111s GGG 99m, both nine points; seat 1, being
	# next, may also chow
	my @hands = ( $HANDS[0], '46m 999p 999s RRR 11m', $DULL, '46m 111p 111s GGG 99m' );
	my $g = Game::Mahjong::Rules->new(seed => 'two-wins', position => { hands => \@hands, wall => [qw(p6 s2)], turn => 0 });
	is_deeply([ $g->check_invariants ], [], 'the written table is sound');
	$g->apply(0, { kind => 'discard', tile => id('m5') });
	is_deeply([ sort keys %{ $g->window->{may} } ], [ 1, 3 ], 'seats 1 and 3 asked');
	ok($g->apply(3, { kind => 'win' }), 'seat 3 claims the win first');
	is($g->phase, 'claim', 'the window stays open');
	is_deeply([ $g->waiting_on ], [ 1 ], 'for seat 1, who is nearer');
	ok($g->apply(1, { kind => 'win' }), 'seat 1 wins too');
	my ($end) = grep { $_->{kind} eq 'hand_end' } $g->take_outcomes;
	is($end->{winner}, 1, 'the nearest seat after the discarder takes it (3.7.2.4)');

	my $h = Game::Mahjong::Rules->new(seed => 'two-wins-2', position => { hands => \@hands, wall => [qw(p6 s2)], turn => 0 });
	$h->apply(0, { kind => 'discard', tile => id('m5') });
	ok($h->apply(1, { kind => 'win' }), 'seat 1, the nearest, wins first');
	is($h->phase, 'discard', 'closed at once: seat 3 is moot');
	is($h->hand_no, 2, 'hand 2 dealt');
};

subtest 'passing' => sub {
	my $g = table();
	$g->apply(0, { kind => 'discard', tile => id('m5') });
	$g->take_outcomes;
	ok($g->apply(1, { kind => 'pass' }), 'seat 1 passes');
	is($g->apply(1, { kind => 'pass' })->code, 'already_answered', 'twice is refused');
	is($g->apply(0, { kind => 'pass' })->code, 'cannot_claim', 'the discarder was not asked');
	is($g->apply(2, { kind => 'win' })->code, 'cannot_claim', 'a claim not offered');
	ok($g->apply(2, { kind => 'pass' }), 'seat 2 passes');
	is_deeply([ $g->waiting_on ], [ 3 ], 'seat 3 left');
	ok($g->apply(3, { kind => 'pass' }), 'seat 3 passes');
	is($g->phase, 'discard', 'closed');
	is($g->turn, 1, 'seat 1 draws');
	is_deeply([ map { $_->{kind} } $g->take_outcomes ], [qw(pass pass pass drew)], 'three passes and a draw');
	is($g->apply(1, { kind => 'pass' })->code, 'wrong_phase', 'a pass after the window is the wrong phase');
};

subtest 'a kong claim needs a replacement to draw' => sub {
	my @hands = ( $HANDS[0], $RUBBISH, '555m 1p 3p 7p 2s 4s 6s 8s E S W', $RUBBISH );
	my $g = Game::Mahjong::Rules->new(seed => 'kong-claim', position => { hands => \@hands, wall => [qw(p6 f2 s2)], turn => 0 });
	is_deeply([ $g->check_invariants ], [], 'the written table is sound');
	$g->apply(0, { kind => 'discard', tile => id('m5') });
	is_deeply($g->window->{may}{2}, [qw(kong pung)], 'seat 2 may kong or pung');
	ok($g->apply(2, { kind => 'kong' }), 'kong');
	is($g->phase, 'discard', 'closed');
	is($g->turn, 2, 'seat 2 on turn');
	is($g->hand_of(2)->melds->[0]->kind, 'kong', 'a kong');
	ok(!$g->hand_of(2)->melds->[0]->concealed, 'exposed');
	is($g->drawn_from, 'back', 'with a replacement from the back');
	is($g->replacement, 'kong', 'after a kong');
	ok(!$g->claimed_this_turn, 'a kong claim does not bar another kong');
	my $dry = Game::Mahjong::Rules->new(seed => 'kong-dry', position => { hands => \@hands, wall => [], turn => 0 });
	$dry->apply(0, { kind => 'discard', tile => id('m5') });
	is_deeply($dry->window->{may}{2}, [qw(pung)], 'with no wall to replace from, only the pung is offered');
};

subtest 'the priority table' => sub {
	my @cases = (
		[ 'win beats pung', [ [ 2, 'pung' ], [ 3, 'win' ] ], 3, 'win' ],
		[ 'pung beats chow', [ [ 1, 'chow' ], [ 2, 'pung' ] ], 2, 'pung' ],
		[ 'win beats chow', [ [ 1, 'chow' ], [ 3, 'win' ] ], 3, 'win' ],
		[ 'a chow alone', [ [ 1, 'chow' ], [ 2, 'pass' ], [ 3, 'pass' ] ], 1, 'chow' ],
	);
	for my $c (@cases) {
		my ($why, $answers, $who, $what) = @$c;
		my $g = table();
		$g->apply(0, { kind => 'discard', tile => id('m5') });
		$g->take_outcomes;
		for my $a (@$answers) {
			my ($seat, $kind) = @$a;
			last unless $g->phase eq 'claim';
			my $move = { kind => $kind };
			$move->{tiles} = [ id('m4'), id('m6') ] if $kind eq 'chow';
			my $r = $g->apply($seat, $move);
			ok($r && !ref $r, "$why: seat $seat, $kind taken") or diag $r->code;
		}
		while ($g->phase eq 'claim') { my ($s) = $g->waiting_on; $g->apply($s, { kind => 'pass' }) }
		my ($claimed) = grep { $_->{kind} eq 'claimed' } $g->take_outcomes;
		is($claimed->{seat}, $who, "$why: seat $who");
		is($claimed->{meld}, $what, "$why: a $what");
	}
};

# THE MUTATION CHECKS, named so they can be run by hand:
#   resolve on the first answer                   -> 'a pung makes the chow moot; the win is still waited on' fails
#   let the wrong seat chow (drop next_seat)      -> 'only the next seat may chow' fails
#   keep a moot seat in waiting_on               -> 'only seat 3 is waited on now' fails
#   pick the farther of two wins                  -> 'the nearest seat after the discarder takes it' fails
subtest 'the mutation checks are written down' => sub {
	pass('see the comment above this subtest');
};

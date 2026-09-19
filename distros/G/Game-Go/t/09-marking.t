#!perl

# The confirmation phase, which Article 9 requires and no other game on the
# roster has.
#
#   9.1  When a player passes his move and his opponent passes in succession,
#        the game stops.
#   9.2  After stopping, the game ends through confirmation and agreement by
#        the two players about the life and death of stones and territory.
#   9.3  If a player requests resumption of a stopped game, his opponent must
#        oblige and has the right to play first.
#
# THE ASSERTION THIS FILE EXISTS FOR is that exactly one seat is waiting in
# every reachable state. The site voids a game whose deadline passes with two
# seats waiting, and a game that has got this far has been played to the end.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

# Play to a stop and hand back the game. Black plays one stone, then both pass.
sub stopped {
	my $g = Game::Go->new(size => 9);
	$g->play($B, $g->point(3, 3));
	$g->pass($W);
	$g->pass($B);
	return $g;
}

subtest 'stopping, and who speaks first' => sub {
	my $g = stopped();
	is($g->phase, 'marking', 'two passes in succession stop play');
	is($g->status, 'active', 'and the game is still active, because stopping is not ending');
	is($g->events->[-1]{kind}, 'stop', 'the log says so');

	my $m = $g->marking;
	isa_ok($m, 'Game::Go::Marking');

	# The proposer is the seat whose turn it already was. Nothing special
	# happens to the turn order when play stops: the same player speaks, and
	# says something other than a move.
	is($m->proposer, $W, 'white passed second, so after black passed it was white to speak');
	is($m->answerer, $B, 'and black answers');
	is($m->turn, $W, 'the proposer speaks first');
	ok(!$m->proposed, 'and has not finished proposing');

	is_deeply($m->dead_points, [], 'NOTHING IS PROPOSED DEAD');
	is_deeply($m->seki_points, [], 'and nothing is proposed seki');
	done_testing();
};

subtest 'exactly one seat is waiting, in every state' => sub {
	# Driven state by state rather than asserted once, because this is the
	# invariant the site's abandon branch punishes.
	my $g = Game::Go->new(size => 9);
	my @states;

	push @states, [ 'fresh', [ $g->waiting_on ] ];
	$g->play($B, $g->point(3, 3));
	push @states, [ 'after a move', [ $g->waiting_on ] ];
	$g->pass($W);
	push @states, [ 'after one pass', [ $g->waiting_on ] ];
	$g->pass($B);
	push @states, [ 'stopped, proposing', [ $g->waiting_on ] ];
	$g->mark($g->marking->proposer, $g->point(3, 3));
	push @states, [ 'after a mark', [ $g->waiting_on ] ];
	$g->done($g->marking->proposer);
	push @states, [ 'proposed, answering', [ $g->waiting_on ] ];
	$g->dispute($g->marking->answerer);
	push @states, [ 'resumed', [ $g->waiting_on ] ];
	$g->pass($g->turn);
	$g->pass($g->turn);
	push @states, [ 'stopped again', [ $g->waiting_on ] ];
	$g->done($g->marking->proposer);
	push @states, [ 'proposed again', [ $g->waiting_on ] ];
	$g->accept($g->marking->answerer);
	push @states, [ 'finished', [ $g->waiting_on ] ];

	for my $s (@states) {
		my ($name, $who) = @$s;
		my $want = $name eq 'finished' ? 0 : 1;
		is(scalar @$who, $want, "$name: $want seat waiting");
	}
	is(scalar @states, 10, 'and ten states were driven, rather than none');
	done_testing();
};

subtest 'the answerer may not speak before the proposal is made' => sub {
	my $g = stopped();
	my $m = $g->marking;

	is_deeply($g->legal($m->answerer), [], 'the answerer is offered nothing');

	my $e = $g->accept($m->answerer);
	isa_ok($e, 'Game::Go::Error', 'accepting early');
	is($e->code, 'not_your_turn', 'is not their turn');

	my $d = $g->dispute($m->answerer);
	is($d->code, 'not_your_turn', 'and neither is disputing');

	my $mark = $g->mark($m->answerer, $g->point(3, 3));
	is($mark->code, 'not_your_turn', 'and the answerer may not mark');
	done_testing();
};

subtest 'the proposer may not answer its own proposal' => sub {
	my $g = stopped();
	my $m = $g->marking;
	$g->done($m->proposer);
	is($m->turn, $m->answerer, 'the turn has passed to the answerer');

	my $e = $g->accept($m->proposer);
	is($e->code, 'not_your_turn', 'the proposer cannot accept');
	my $again = $g->done($m->proposer);
	is($again->code, 'not_your_turn', 'nor say done twice');
	my $late = $g->mark($m->proposer, $g->point(3, 3));
	is($late->code, 'not_your_turn', 'nor mark after proposing');
	done_testing();
};

subtest 'no stone can be played while the game is being counted' => sub {
	my $g = stopped();
	for my $colour ($B, $W) {
		my $e = $g->play($colour, $g->point(5, 5));
		isa_ok($e, 'Game::Go::Error', 'a stone');
		is($e->code, 'still_marking', 'is refused for being in the wrong phase');
		like($e->message, qr/being scored/, 'with a message about scoring');
	}
	my $p = $g->pass($B);
	is($p->code, 'still_marking', 'and so is a pass');
	done_testing();
};

subtest 'marking toggles, and the log records which way' => sub {
	my $g = stopped();
	my $m = $g->marking;
	my $pt = $g->point(3, 3);

	my $on = $g->mark($m->proposer, $pt);
	is($on->kind, 'mark', 'the first touch marks');
	is(scalar @{ $m->dead_points }, 1, 'one chain is dead');
	is($g->events->[-1]{kind}, 'mark', 'and the log says mark');
	is($g->events->[-1]{payload}{chain}, $pt, 'naming the chain');

	my $off = $g->mark($m->proposer, $pt);
	is($off->kind, 'unmark', 'the second unmarks');
	is(scalar @{ $m->dead_points }, 0, 'and the set is empty again');
	is($g->events->[-1]{kind}, 'unmark', 'with the log saying unmark');

	# A chain is named by its LOWEST point and not by the engine's internal
	# root, which is whichever stone won a union and moves when chains merge.
	# A mark in a log has to mean the same thing on a replay.
	is($g->events->[-1]{payload}{chain}, $pt, 'and the chain id is a point of the chain');

	my $seki = $g->mark_seki($m->proposer, $g->point(5, 5));
	is($seki->kind, 'seki', 'an empty point can be marked seki');
	is(scalar @{ $m->seki_points }, 1, '...');
	is($g->mark_seki($m->proposer, $g->point(5, 5))->kind, 'unseki', 'and unmarked');

	my $bad = $g->mark_seki($m->proposer, $pt);
	is($bad->code, 'off_board', 'a point with a stone on it is not a region');
	my $none = $g->mark($m->proposer, $g->point(7, 7));
	is($none->code, 'not_a_chain', 'and an empty point is not a chain');
	done_testing();
};

subtest 'Benson is a veto: an alive chain cannot be agreed dead' => sub {
	# A black group with two one-point eyes, built with put() so the rules
	# layer is not what made it, then stopped.
	my $g = Game::Go->new(size => 9);
	for my $spec ([1,0],[2,0],[3,0],[4,0],[5,0],[1,1],[3,1],[5,1],[1,2],[2,2],[3,2],[4,2],[5,2]) {
		$g->play($B, $g->point(@$spec));
		$g->pass($W) unless $spec->[0] == 5 && $spec->[1] == 2;
	}
	$g->pass($W);
	$g->pass($B);
	is($g->phase, 'marking', 'the game stopped');

	my $m = $g->marking;
	my $refused = $g->mark($m->proposer, $g->point(1, 0));
	isa_ok($refused, 'Game::Go::Error', 'marking the two-eyed group');
	is($refused->code, 'alive_chain', 'is refused');
	like($refused->message, qr/alive whatever happens/, 'saying why');

	# WITHOUT THIS a player who has lost can mark the opponent's living wall
	# dead, refuse to accept, and force the dispute path every game.
	my $moves = $g->legal($m->proposer);
	my %marks = map { $_->point => 1 } grep { $_->kind eq 'mark' } @$moves;
	ok(!$marks{ $g->point(1, 0) }, 'and it is not even offered');
	done_testing();
};

subtest 'accept ends the game, and says how it was scored' => sub {
	my $g = stopped();
	my $m = $g->marking;
	$g->done($m->proposer);

	my $moves = $g->legal($m->answerer);
	is_deeply([ sort map { $_->kind } @$moves ], [ 'accept', 'dispute' ],
		'the answerer has two things it can say');

	$g->accept($m->answerer);
	is($g->status, 'finished', 'accepting ends the game');
	is($g->result, 'score', 'by a score');
	is($g->scored_by, 'territory', 'reached by agreement');
	is($g->phase, 'play', 'and the confirmation phase is over');
	is($g->marking, undef, '...');
	is_deeply([ $g->waiting_on ], [], 'nobody is waiting');

	my $end = $g->events->[-1];
	is($end->{kind}, 'game_end', 'the log ends with the end');
	is($end->{payload}{scored_by}, 'territory', 'recording how');

	# When this file was written the scorer did not exist and this asserted
	# that the winner was undef. It exists now, so the assertion is what it
	# was always about: accepting settles WHETHER the game is scored and by
	# which rule, and the counting follows from that.
	ok(defined $g->winner, 'and a winner falls out of the count');
	isa_ok($g->outcome, 'Game::Go::Result', 'with the workings');
	is($g->outcome->scored_by, 'territory', 'scored by the rule the players agreed');
	done_testing();
};

subtest 'disputing sends it back, and the PROPOSER moves' => sub {
	my $g = stopped();
	my $m = $g->marking;
	my $proposer = $m->proposer;
	$g->done($proposer);

	my $d = $g->dispute($m->answerer);
	is($d->kind, 'dispute', 'the answerer disputes');
	is($g->phase, 'play', 'play resumes');
	is($g->status, 'active', 'the game is still going');
	is($g->marking, undef, 'and the proposal is gone');
	is($g->disputes, 1, 'one dispute spent');

	# ARTICLE 9.3: "his opponent must oblige AND HAS THE RIGHT TO PLAY FIRST."
	# The answerer asked, so the PROPOSER moves. This reads backwards until
	# you see what it is for: asking to resume costs you the initiative, and
	# that is the only thing stopping a losing player asking forever.
	is($g->turn, $proposer, 'and the proposer has the move, not the disputer');

	my $resumed = $g->events->[-1];
	is($resumed->{kind}, 'resumed', 'the log records the resumption');
	is($resumed->{payload}{first}, Game::Go::Rules::letter($proposer), 'naming who got the move');

	ok(scalar @{ $g->legal($proposer) } > 1, 'and there are stones to play again');
	done_testing();
};

subtest 'the disputes run out, and the game is scored without agreement' => sub {
	my $g = Game::Go->new(size => 9);
	$g->play($B, $g->point(3, 3));

	for my $round (1 .. 3) {
		$g->pass($g->turn);
		$g->pass($g->turn);
		is($g->phase, 'marking', "round $round: a confirmation phase");
		$g->done($g->marking->proposer);
		my $d = $g->dispute($g->marking->answerer);
		is($d->kind, 'dispute', "round $round: disputed");
		is($g->disputes, $round, "round $round: counted");
	}

	# The fourth stoppage has NO confirmation phase at all. Skipping it is
	# deliberate: forcing the answerer to accept would let the proposer put up
	# an absurd dead set on the last round and win with it, so the abusable
	# step is removed rather than policed.
	$g->pass($g->turn);
	$g->pass($g->turn);
	is($g->phase, 'play', 'the fourth stop opens no confirmation phase');
	is($g->status, 'finished', 'the game is simply over');
	is($g->scored_by, 'area', 'scored by area, which needs nobody agreeing');

	my @kinds = map { "$_->{actor}/$_->{kind}" } @{ $g->events };
	is($kinds[-3], 'sys/stop', 'the log shows the stop');
	is($kinds[-2], 'sys/area', 'then the fall-through');
	is($kinds[-1], 'sys/game_end', 'then the end');
	done_testing();
};

subtest 'the cap is enforced in one place, and legal reflects it' => sub {
	# THERE IS NO "fourth dispute refused" ERROR, and there should not be.
	# _stop finishes the game outright once the disputes are spent, so a
	# confirmation phase never exists in a state where a fourth could be
	# asked for. A guard inside dispute() would be unreachable code no test
	# could exercise, and one rule enforced in two places is two places for it
	# to disagree.
	#
	# What is observable, and what this asserts, is that the OFFER goes away.
	my $g = Game::Go->new(size => 9);
	$g->play($B, $g->point(3, 3));

	for my $spent (0 .. 2) {
		$g->pass($g->turn);
		$g->pass($g->turn);
		$g->done($g->marking->proposer);
		my @kinds = sort map { $_->kind } @{ $g->legal($g->marking->answerer) };
		is_deeply(\@kinds, [ 'accept', 'dispute' ],
			"with $spent spent, a dispute is still offered");
		$g->dispute($g->marking->answerer);
	}
	is($g->disputes, 3, 'three spent');

	# And with three spent there is no confirmation phase to be offered
	# anything in: the next stop is the end of the game.
	$g->pass($g->turn);
	$g->pass($g->turn);
	is($g->status, 'finished', 'the next stop finishes it');
	is($g->marking, undef, 'with no confirmation phase to dispute in');
	is_deeply($g->legal($B), [], 'and nothing legal for anybody');
	done_testing();
};

subtest 'a whole confirmation phase replays' => sub {
	my $g = Game::Go->new(size => 9);
	$g->play($B, $g->point(3, 3));
	$g->play($W, $g->point(5, 5));
	$g->pass($B);
	$g->pass($W);
	$g->mark($g->marking->proposer, $g->point(3, 3));
	$g->mark_seki($g->marking->proposer, $g->point(7, 7));
	$g->done($g->marking->proposer);
	$g->dispute($g->marking->answerer);
	$g->pass($g->turn);
	$g->pass($g->turn);
	$g->done($g->marking->proposer);
	$g->accept($g->marking->answerer);

	is($g->status, 'finished', 'the original finished');
	is($g->scored_by, 'territory', 'by agreement');

	my $r = Game::Go->new(size => 9);
	my $n = eval { $r->replay($g->events) };
	ok(!$@, 'and the whole thing replays') or diag $@;
	is($n, scalar @{ $g->events }, 'every event');
	is($r->status, $g->status, 'same status');
	is($r->scored_by, $g->scored_by, 'same scoring rule');
	is($r->disputes, $g->disputes, 'same dispute count');
	is_deeply(
		[ map { "$_->{actor}/$_->{kind}" } @{ $r->events } ],
		[ map { "$_->{actor}/$_->{kind}" } @{ $g->events } ],
		'and the same log, event for event'
	);
	done_testing();
};

done_testing();

#!perl

# THE BOT HAS TO PLAY THE CONFIRMATION PHASE, or a bot game strands in it and
# the clock times the bot out of a game it may well have won.
#
# Article 9.2 ends a game "through confirmation and agreement by the two players
# about the life and death of stones and territory", and a bot is one of the two
# players. It judges dead stones by PLAYOUTS rather than by heuristics, which is
# what `final_status_list dead` means in every playout engine, and it never
# proposes a mark the rules would refuse.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Bot;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

# Play to a stop with a stone each, so there is something to judge.
sub stopped {
	my $g = Game::Go->new(size => 9, seed => 'm' x 32);
	$g->play($B, $g->point(2, 2));
	$g->play($W, $g->point(6, 6));
	$g->pass($B);
	$g->pass($W);
	return $g;
}

subtest 'the proposer proposes and then finishes' => sub {
	my $g = stopped();
	my $m = $g->marking;
	my $bot = Game::Go::Bot->new(level => 1, seed => 'p');

	# It offers marks until it has nothing left to mark, then `done`. Applied in
	# order, as the caller would.
	my $guard = 0;
	my $marked = 0;
	while ($guard++ < 90) {
		my $move = $bot->mark($g, $m->proposer);
		ok($move, 'the proposer has something to say') if $guard == 1;
		last unless $move;
		last if $move->kind eq 'done';
		is($move->kind, 'mark', 'and what it says is a mark');
		my $out = $g->mark($m->proposer, $move->point);
		isa_ok($out, 'Game::Go::Move', 'which the rules accept');
		$marked++;
	}

	cmp_ok($guard, '<', 90, 'it stopped proposing rather than looping');
	my $done = $bot->mark($g, $m->proposer);
	is($done->kind, 'done', 'and finished with done');
	done_testing();
};

subtest 'it never proposes a mark the rules would refuse' => sub {
	# A BENSON CHAIN CANNOT BE AGREED DEAD, and a refused bot move is a
	# stranded game. So the bot filters its own proposal against the alive set
	# before offering it.
	my $g = Game::Go->new(size => 9, seed => 'a' x 32);
	# a two-eyed black group, which is unconditionally alive
	for my $cr ([1,0],[2,0],[3,0],[4,0],[5,0],[1,1],[3,1],[5,1],[1,2],[2,2],[3,2],[4,2],[5,2]) {
		$g->play($B, $g->point(@$cr));
		$g->pass($W);
	}
	$g->pass($B);
	$g->pass($W);
	is($g->phase, 'marking', 'the game stopped');

	my $alive = 0;
	for my $cr ([1,0],[3,1],[5,2]) {
		$alive++ if $g->is_alive($g->point(@$cr));
	}
	is($alive, 3, 'the black group is unconditionally alive');

	my $m = $g->marking;
	my $bot = Game::Go::Bot->new(level => 1, seed => 'v');
	my $guard = 0;
	while ($guard++ < 90) {
		my $move = $bot->mark($g, $m->proposer) or last;
		last if $move->kind eq 'done';
		my $out = $g->mark($m->proposer, $move->point);
		isnt(ref $out, 'Game::Go::Error',
			'every mark the bot proposed was accepted') if $guard < 4;
		last if ref $out eq 'Game::Go::Error';
	}

	# And the alive group is not among the marks.
	my %dead = map { $_ => 1 } @{ $m->dead_points };
	ok(!$dead{ $g->chain_id($g->point(1, 0)) }, 'the alive group was never marked');
	done_testing();
};

subtest 'the answerer accepts an agreeing proposal' => sub {
	my $g = stopped();
	my $m = $g->marking;
	$g->done($m->proposer);          # an empty proposal

	my $bot = Game::Go::Bot->new(level => 1, seed => 'ans');
	my $move = $bot->mark($g, $m->answerer);
	ok($move, 'the answerer answers');
	like($move->kind, qr/\A(?:accept|dispute)\z/, 'with an accept or a dispute');

	# Whichever it is, applying it is accepted by the rules.
	my $out = $move->kind eq 'accept'
		? $g->accept($m->answerer)
		: $g->dispute($m->answerer);
	isnt(ref $out, 'Game::Go::Error', 'and the rules accept it');
	done_testing();
};

subtest 'it disputes at most ONCE in a game' => sub {
	# A bot that disputed on every round trip against a stubborn human would
	# turn a finished game into an unbounded one, and between a bot and a
	# person the bot is the party that should yield.
	my $bot = Game::Go::Bot->new(level => 1, seed => 'd');
	my $disputes = 0;

	my $g = Game::Go->new(size => 9, seed => 'd' x 32);
	$g->play($B, $g->point(2, 2));
	$g->play($W, $g->point(6, 6));

	for my $round (1 .. 4) {
		last unless $g->status eq 'active';
		$g->pass($g->turn);
		$g->pass($g->turn);
		last unless $g->phase eq 'marking';

		my $m = $g->marking;
		$g->done($m->proposer);

		my $move = $bot->mark($g, $m->answerer) or last;
		if ($move->kind eq 'dispute') {
			$disputes++;
			$g->dispute($m->answerer);
			# put a move on the board so the next stop is a fresh one
			my ($who) = $g->waiting_on;
			my $legal = $g->legal($who);
			my ($play) = grep { $_->kind eq 'play' } @$legal;
			$g->play($who, $play->point) if $play;
		}
		else {
			$g->accept($m->answerer);
			last;
		}
	}

	cmp_ok($disputes, '<=', 1, "it disputed $disputes times, never more than once");
	done_testing();
};

subtest 'a bot game reaches a score with no person in it' => sub {
	# THE WHOLE POINT. If the bot could not play this phase the game would sit
	# waiting on a seat that is not a person, and the deadline would time the
	# bot out of a game it had won.
	my $g = Game::Go->new(size => 9, seed => 'f' x 32);
	my %bot = (
		$B => Game::Go::Bot->new(level => 1, seed => 'b'),
		$W => Game::Go::Bot->new(level => 1, seed => 'w'),
	);

	my $n = 0;
	my $stranded = 0;
	while ($g->status eq 'active' && $n++ < 400) {
		my ($who) = $g->waiting_on;
		last unless defined $who;
		my $m = $bot{$who}->choose($g, $who);
		unless ($m) { $stranded = 1; last }
		my $out =
			  $m->kind eq 'play'    ? $g->play($who, $m->point)
			: $m->kind eq 'pass'    ? $g->pass($who)
			: $m->kind eq 'mark'    ? $g->mark($who, $m->point)
			: $m->kind eq 'done'    ? $g->done($who)
			: $m->kind eq 'accept'  ? $g->accept($who)
			: $m->kind eq 'dispute' ? $g->dispute($who)
			: undef;
		last if ref $out eq 'Game::Go::Error';
	}

	is($stranded, 0, 'the game never stranded on a bot with nothing to say');
	is($g->status, 'finished', 'it finished');
	is($g->result, 'score', 'by a score');
	ok(defined $g->winner, 'with a winner');
	isa_ok($g->outcome, 'Game::Go::Result', 'and the workings');
	done_testing();
};

subtest 'choose hands off to mark during the confirmation phase' => sub {
	# The site's bot driver calls `choose` and nothing else, so `choose` has to
	# be the whole interface: a bot that only knew about board moves would
	# return undef here and strand the game.
	my $g = stopped();
	my $bot = Game::Go::Bot->new(level => 1, seed => 'h');
	my ($who) = $g->waiting_on;

	my $move = $bot->choose($g, $who);
	ok($move, 'choose returns something during confirmation');
	like($move->kind, qr/\A(?:mark|done)\z/, 'and it is a confirmation move');
	done_testing();
};

done_testing();

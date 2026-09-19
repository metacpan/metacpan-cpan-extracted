#!perl

# DETERMINISM, WHICH IS THE ONE PROMISE THE EVENT LOG MAKES.
#
# The site publishes a game's seed when the game ends so that anybody can
# re-verify a bot's play. That only means anything if the same seed gives the
# same moves, on every machine and in every process. Two things in this
# distribution could break it quietly, and both are asserted here.

use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256);

use Game::Go;
use Game::Go::Bot;
use Game::Go::Engine;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

subtest 'the Perl mirror of xorshift32 digests identically to the C' => sub {
	# THE GENERATOR IS THREE LINES AND THIS IS WHY IT IS THOSE THREE:
	#
	#     x ^= x << 13;   x ^= x >> 17;   x ^= x << 5;
	#
	# Not a 64-bit generator and nothing with a 32x32 multiply. On a perl with
	# 32-bit integers a 64-bit product goes silently through an NV, whose
	# mantissa is 53 bits, and the low bits are lost. A generator anybody might
	# want to mirror from Perl, as this test does, has to live in add, xor and
	# shift.
	my @from_c;
	my $s = 12345;
	push @from_c, ($s = Game::Go::Engine::_prng_next($s)) for 1 .. 4096;

	my @from_perl;
	my $p = 12345;
	for (1 .. 4096) {
		$p ^= ($p << 13) & 0xFFFFFFFF; $p &= 0xFFFFFFFF;
		$p ^= ($p >> 17);
		$p ^= ($p << 5)  & 0xFFFFFFFF; $p &= 0xFFFFFFFF;
		push @from_perl, $p;
	}

	is(scalar @from_c, 4096, 'four thousand and ninety-six from the C');
	is(scalar @from_perl, 4096, 'and as many from Perl');
	is(
		unpack('H*', sha256(pack 'N*', @from_c)),
		unpack('H*', sha256(pack 'N*', @from_perl)),
		'and the two streams digest to the same thing'
	);

	# Not a constant stream, which a mirror of a broken generator would also be.
	my %distinct = map { $_ => 1 } @from_c;
	cmp_ok(scalar keys %distinct, '>', 4000, 'with almost no repeats in it');
	done_testing();
};

subtest 'a zero state is corrected, not accepted' => sub {
	# ZERO IS A FIXED POINT of xorshift: 0 xor anything shifted is still 0. A
	# zero seed would make every playout identical and every test would still
	# pass, which is the worst kind of silence.
	isnt(Game::Go::Engine::_prng_next(0), 0, 'a zero state does not stay zero');

	my $a = Game::Go::Engine::_prng_next(0);
	my $b = Game::Go::Engine::_prng_next(0);
	is($a, $b, 'and the correction is deterministic');
	done_testing();
};

subtest 'the same seed gives the same move, in one process' => sub {
	my $g = Game::Go->new(size => 9);
	my @picks;
	for (1 .. 3) {
		my $bot = Game::Go::Bot->new(level => 2, seed => 'fixed');
		push @picks, $bot->choose($g, $B)->point;
	}
	is($picks[1], $picks[0], 'twice');
	is($picks[2], $picks[0], 'three times');

	# And a different seed gives a different move, or the first assertion would
	# pass against a bot that ignored its seed entirely.
	my $other = Game::Go::Bot->new(level => 2, seed => 'different')->choose($g, $B)->point;
	isnt($other, $picks[0], 'and a different seed gives a different move');
	done_testing();
};

subtest 'the same seed gives the same move in a FRESH process' => sub {
	# THE SHAPE OF TEST THAT CATCHES A HASH IN THE SEARCH. If the selection
	# depended on Perl's or the allocator's iteration order it would be
	# reproducible within one process and not across two, and every other test
	# in this suite runs in one process.
	my $code = <<'RUN';
use blib;
use Game::Go;
use Game::Go::Bot;
my $g = Game::Go->new(size => 9);
my $m = Game::Go::Bot->new(level => 2, seed => 'fixed')->choose($g, Game::Go::BLACK);
print $m->point, "\n";
RUN
	my $first  = `$^X -e '$code' 2>&1`;
	my $second = `$^X -e '$code' 2>&1`;
	chomp for $first, $second;

	like($first, qr/\A[0-9]+\z/, "a fresh process chose a point ($first)") or diag $first;
	is($second, $first, 'and another fresh process chose the same one');

	my $here = Game::Go::Bot->new(level => 2, seed => 'fixed')
		->choose(Game::Go->new(size => 9), $B)->point;
	is($first, $here, 'which is also what this process chooses');
	done_testing();
};

subtest 'the seed carries the seat and the move number' => sub {
	# THE SEAT, so the two colours do not play one opening from one game seed.
	my $g = Game::Go->new(size => 9);
	my $bot = Game::Go::Bot->new(level => 2, seed => 'one');
	my $black = $bot->choose($g, $B)->point;
	$g->play($B, $black);
	my $white = $bot->choose($g, $W)->point;
	isnt($white, $black, 'the two seats do not choose from the same stream');

	# THE MOVE NUMBER, so a position reached twice is not searched with the same
	# stream twice. A dispute sends a game back to the board, which makes that
	# genuinely possible rather than theoretical.
	my $h = Game::Go->new(size => 9);
	my $b2 = Game::Go::Bot->new(level => 2, seed => 'one');
	my $at_move_0 = $b2->choose($h, $B)->point;
	$h->play($B, $at_move_0);
	$h->play($W, $h->point(8, 8));
	my $at_move_2 = $b2->choose($h, $B)->point;
	isnt($at_move_2, $at_move_0, 'and the stream moves on with the game');
	done_testing();
};

subtest 'a whole bot game replays to itself' => sub {
	# THE PROMISE, END TO END. Two bots play, the log is replayed into a fresh
	# game, and the two positions are compared.
	my $g = Game::Go->new(size => 9, seed => 'x' x 32);
	my %bot = (
		$B => Game::Go::Bot->new(level => 1, seed => 'b'),
		$W => Game::Go::Bot->new(level => 1, seed => 'w'),
	);

	my $n = 0;
	while ($g->status eq 'active' && $n++ < 400) {
		my ($who) = $g->waiting_on;
		last unless defined $who;
		my $m = $bot{$who}->choose($g, $who) or last;
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

	is($g->status, 'finished', 'the game finished');
	cmp_ok(scalar @{ $g->events }, '>', 20, 'with a log worth replaying');

	my $r = Game::Go->new(size => 9, seed => 'x' x 32);
	my $seen = eval { $r->replay($g->events) };
	ok(!$@, 'and it replays') or diag $@;
	is($r->board->to_text, $g->board->to_text, 'to the same position');
	is($r->result, $g->result, 'the same result');
	is($r->winner, $g->winner, 'and the same winner');
	done_testing();
};

done_testing();

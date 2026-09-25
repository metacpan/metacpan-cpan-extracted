#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Mahjong;
use Play;

sub key { return Play::move_key($_[0]) }

plan tests => 7;

subtest 'the bag' => sub {
	is_deeply([ Game::Mahjong::Bot::levels() ], [ 1, 2, 3 ], 'three levels');
	cmp_ok(scalar @Game::Mahjong::Bot::LADDER, '>=', 2, 'a bag');
	my @l = @Game::Mahjong::Bot::LADDER;
	is_deeply(\@l, [ sort { $a <=> $b } @l ], 'weakest first');
	is($l[-1], 3, 'the top rung last: hint reaches for it');
	ok(!eval { Game::Mahjong::Bot->new(level => 4); 1 }, 'level 4 dies');
	ok(!eval { Game::Mahjong::Bot->new(level => 0); 1 }, 'level 0 dies');
};

subtest 'undef off turn, a legal move on turn' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'bot');
	my $bot = Game::Mahjong::Bot->new(level => 2, seed => 'bot');
	is($bot->choose($g, 1), undef, 'seat 1 is not waited on');
	my $m = $bot->choose($g, 0);
	ok($m, 'seat 0 gets a move');
	ok((grep { key($_) eq key($m) } $g->legal(0)), 'and it is legal');
};

subtest 'every rung plays legal moves through five hundred positions' => sub {
	for my $level (1 .. 3) {
		my $bot = Game::Mahjong::Bot->new(level => $level, seed => "legal-$level");
		my $n = 0;
		my ($g, $bad) = Play::play_game(seed => "legal-$level", check => 1, stop_after => 500,
			default => sub { my ($rules, $seat, @legal) = @_; $n++; my $m = $bot->choose($rules, $seat); $m });
		is_deeply($bad, [], "level $level: no invariant broke, no move refused") or diag join "\n", @$bad;
		cmp_ok($n, '>=', 500, "level $level: five hundred moves");
	}
};

subtest 'deterministic, and the seat is in the seed' => sub {
	my @a = map { my $g = Game::Mahjong::Rules->new(seed => 'det'); key(Game::Mahjong::Bot->new(level => 3, seed => 'det')->choose($g, 0)) } 1 .. 3;
	is($a[1], $a[0], 'the same move twice');
	is($a[2], $a[0], 'and thrice');
};

subtest 'hint is the top rung' => sub {
	my $g = Game::Mahjong::Rules->new(seed => 'hint');
	my $one = Game::Mahjong::Bot->new(level => 1, seed => 'hint');
	my $three = Game::Mahjong::Bot->new(level => 3, seed => 'hint');
	is(key($one->hint($g, 0)), key($three->choose($g, 0)), 'a level-one bot hints what level three would play');
	is($one->hint($g, 2), undef, 'no hint for a seat not waited on');
};

subtest 'a whole game of four level-two bots' => sub {
	my $bot = Game::Mahjong::Bot->new(level => 2, seed => 'game');
	my ($g, $bad, $census) = Play::play_game(seed => 'game', check => 1,
		default => sub { my ($rules, $seat) = @_; $bot->choose($rules, $seat) });
	is_deeply($bad, [], 'no invariant broke') or diag join "\n", @$bad;
	is($g->status, 'finished', 'finished');
	is($census->{hands}, 16, 'sixteen hands');
	diag sprintf 'level 2 x4: moves %d, wins %d (self %d, discard %d), exhausted %d', $census->{moves}, $census->{wins}, $census->{by_self} || 0, $census->{by_discard} || 0, $census->{by_exhausted} || 0;
	cmp_ok($census->{wins}, '>=', 1, 'at least one hand won');
};

subtest 'level three beats level one over a few games' => sub {
	my ($three_pts, $one_pts) = (0, 0);
	for my $n (1 .. 6) {
		my $seat3 = $n % 4;
		my %bots = map { $_ => Game::Mahjong::Bot->new(level => ($_ == $seat3 ? 3 : 1), seed => "ladder-$n") } 0 .. 3;
		my ($g) = Play::play_game(seed => "ladder-$n", chooser => { map { my $s = $_; $s => sub { my ($rules, $seat) = @_; $bots{$s}->choose($rules, $seat) } } 0 .. 3 });
		$three_pts += $g->totals->[$seat3];
		$one_pts += $g->totals->[$_] for grep { $_ != $seat3 } 0 .. 3;
	}
	diag sprintf 'six games: level 3 total %d, the three level 1s together %d', $three_pts, $one_pts;
	cmp_ok($three_pts, '>', 0, 'level three ends above zero');
};

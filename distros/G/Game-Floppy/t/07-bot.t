#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Floppy;
use Game::Floppy::Bot;

# THE LADDER IS THE METHOD. Three levels differ in WHEN they start down
# toward the next gap, which is what decides a drop; the tests assert the
# ORDER of their results over seeded games with a tick cap, never the numbers
# (those are measured in plan_update_floppy/02), that no level flaps into the
# sky, and that the same seed is the same flight twice.

sub fly {
	my ($level, $seed, $cap) = @_;
	my $game = Game::Floppy->new(seed => $seed);
	my @chosen;
	while ($game->status ne 'finished' && $game->ticks < $cap) {
		my $flap = Game::Floppy::Bot->choose($game, level => $level);
		push @chosen, $flap;
		$game->flap if $flap;
		$game->tick;
	}
	return ($game, \@chosen);
}

subtest 'the ladder' => sub {
	is_deeply([ Game::Floppy::Bot->levels ], [ 1, 2, 3 ], 'three levels');
	like(Game::Floppy::Bot->describe(1), qr/short-sighted/, 'level 1');
	like(Game::Floppy::Bot->describe(2), qr/far-sighted/, 'level 2');
	like(Game::Floppy::Bot->describe(3), qr/sits low/, 'level 3');
	like(Game::Floppy::Bot->describe, qr/sits low/, 'and the default is the top');
	is(Game::Floppy::Bot->near, 120, 'level 1 counts a tube within 120');
	my $bad = eval { Game::Floppy::Bot->describe(4) };
	like($@, qr/a level is one of 1 2 3, not '4'/, 'a level off the ladder dies');
	$bad = eval { Game::Floppy::Bot->choose(Game::Floppy->new, level => 'x') };
	like($@, qr/not 'x'/, 'and so does one that is not a number');
};

subtest 'each level does better than the one below' => sub {
	my %mean;
	for my $level (1 .. 3) {
		my $total = 0;
		for my $n (1 .. 30) {
			my ($game) = fly($level, "order$n", 3000);
			$total += $game->score;
		}
		$mean{$level} = $total / 30;
	}
	cmp_ok($mean{2}, '>', $mean{1}, "far-sighted ($mean{2}) beats short-sighted ($mean{1})");
	cmp_ok($mean{3}, '>=', $mean{2}, "sits low ($mean{3}) is at least far-sighted ($mean{2})");
};

subtest 'the targets' => sub {
	my $game = Game::Floppy->new(seed => 'target');
	is(Game::Floppy::Bot->target($game, $_), 200, "level $_ aims at the middle with no tube") for 1 .. 3;
	for (1 .. 100) { $game->flap if Game::Floppy::Bot->choose($game, level => 2); $game->tick }
	my $tube = $game->tubes->[0];
	ok($tube, 'a tube is on the field at tick 100');
	cmp_ok($tube->{x} - 80, '>', 120, 'and it is beyond 120 of the bird');
	is(Game::Floppy::Bot->target($game, 1), 200, 'level 1 still aims at the middle');
	is(Game::Floppy::Bot->target($game, 2), ($tube->{gap_top} + $tube->{gap_bottom}) / 2, 'level 2 at the gap centre');
	is(Game::Floppy::Bot->target($game, 3), $tube->{gap_bottom} - 24 - 9, 'level 3 at the gap bottom less a radius and a margin');
	cmp_ok(Game::Floppy::Bot->target($game, 3), '>', Game::Floppy::Bot->target($game, 2), 'which is below the centre');
	while ($game->tubes->[0]{x} - 80 > 120) { $game->flap if Game::Floppy::Bot->choose($game, level => 2); $game->tick }
	is(Game::Floppy::Bot->target($game, 1), Game::Floppy::Bot->target($game, 2), 'once the tube is within 120, level 1 aims at the centre too');
};

subtest 'level with the target, the bot does not flap' => sub {
	my $game = Game::Floppy->new(seed => 'level');
	$game->tick for 1 .. 8;
	is($game->bird->{y}, 200, 'the bird has fallen to 200, the middle');
	is(Game::Floppy::Bot->target($game, 1), 200, 'which is the target with no tube');
	is(Game::Floppy::Bot->choose($game, level => 1), 0, 'so it does not flap');
	$game->tick;
	is($game->bird->{y}, 203, 'one more fall');
	is(Game::Floppy::Bot->choose($game, level => 1), 1, 'and now it flaps');
};

subtest 'no level flaps into the sky' => sub {
	my $checked = 0;
	for my $level (1 .. 3) {
		my $game = Game::Floppy->new(seed => "sky$level", height => 400);
		my $fly_high = 0;
		while ($game->status ne 'finished' && $game->ticks < 2000) {
			my $y = $game->bird->{y};
			my $flap = Game::Floppy::Bot->choose($game, level => $level);
			fail("level $level flapped at y $y, into the sky") if $flap && $y + 3 - 30 < 0;
			$checked++;
			$game->flap if $flap;
			my $step = $game->tick;
			fail("level $level died in the sky") if $step->{died} && $step->{died} eq 'sky';
		}
	}
	cmp_ok($checked, '>', 1000, "$checked choices checked");
};

subtest 'the same seed is the same flight twice' => sub {
	for my $level (1 .. 3) {
		my (undef, $first) = fly($level, 'twice', 1500);
		my (undef, $second) = fly($level, 'twice', 1500);
		is_deeply($second, $first, "level $level, " . scalar(@$first) . ' choices');
	}
};

subtest 'choose on a finished game is undef' => sub {
	my $game = Game::Floppy->new;
	$game->quit;
	is(Game::Floppy::Bot->choose($game), undef, 'undef');
};

subtest 'level 3 lives through the whole cap' => sub {
	my ($game) = fly(3, 'long', 4000);
	is($game->status, 'active', 'alive at 4,000 ticks') or diag $game->result->stringify;
	cmp_ok($game->passed, '>=', 38, 'having passed ' . $game->passed . ' tubes');
};

done_testing();

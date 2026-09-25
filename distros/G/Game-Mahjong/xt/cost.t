#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Time::HiRes ();

use Game::Mahjong;
use Play;

# THE COST. The time of `choose` at every rung over five hundred seeded
# positions after warm-up. The mark: rung 3 p95 under 12 ms, so three bots
# answer inside one move transaction under the site's 50 ms.

sub pct { my ($p, @v) = @_; @v = sort { $a <=> $b } @v; return $v[ int($#v * $p) ] }

plan tests => 3;

for my $level (1 .. 3) {
	my $bot = Game::Mahjong::Bot->new(level => $level, seed => "cost-$level");
	my @ms;
	Play::play_game(seed => "cost-$level", stop_after => 520, default => sub {
		my ($rules, $seat) = @_;
		my $t0 = Time::HiRes::time();
		my $m = $bot->choose($rules, $seat);
		push @ms, (Time::HiRes::time() - $t0) * 1000;
		return $m;
	});
	splice @ms, 0, 20;
	diag sprintf 'rung %d: choose median %.2f ms, p95 %.2f ms, max %.2f ms over %d moves', $level, pct(0.5, @ms), pct(0.95, @ms), pct(1, @ms), scalar @ms;
	if ($level == 3) { cmp_ok(pct(0.95, @ms), '<', 12, 'rung 3 p95 under 12 ms') }
	else { cmp_ok(pct(0.95, @ms), '<', 12, "rung $level p95 under 12 ms") }
}

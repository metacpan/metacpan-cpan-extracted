#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Time::HiRes ();

use Game::Mahjong;
use Play;

# THE CENSUS. A bounded number of whole games with an eager player (wins
# when it can, claims when it can) and a dull one (passes everything), every
# position through the invariants, and the numbers printed: moves a hand and
# a game (median, p95, max), the split of moves by kind, windows a hand,
# answers a hand, how hands end. The p95 of moves a game is the number the
# adapter's `limits` is declared from, and the overview's length paragraph
# is rewritten with it. Bounded in work: SOAK games, default 200.

my $SOAK = $ENV{SOAK} || 200;

sub pct { my ($p, @v) = @_; @v = sort { $a <=> $b } @v; return $v[ int($#v * $p) ] }
sub mean { my $s = 0; $s += $_ for @_; return @_ ? $s / @_ : 0 }

plan tests => 4;

my (@moves_game, @moves_hand, %by, $windows, $answers, $claims, $kongs, $robs, $discards, %per_seat);
my ($lowest, $highest) = (0, 0);
my $t0 = Time::HiRes::time();
my @bad;

for my $n (1 .. $SOAK) {
	my $seed = "census-$n";
	my $rng = Play::new_rng($seed);
	my $chooser = { 0 => Play::eager_chooser($rng), 1 => Play::eager_chooser($rng), 2 => Play::eager_chooser($rng), 3 => ($n % 4 ? Play::eager_chooser($rng) : Play::dull_chooser()) };
	my %seat_moves;
	my ($g, $b, $c) = Play::play_game(seed => $seed, chooser => $chooser, check => 1,
		on_move => sub { my ($rules, $seat) = @_; $seat_moves{$seat}++ });
	push @bad, map { "$seed: $_" } @$b;
	push @moves_game, $c->{moves};
	my $hands = $c->{hands} || 1;
	push @moves_hand, $c->{moves} / $hands;
	$by{$_} += $c->{"by_$_"} || 0 for qw(self discard rob exhausted);
	$windows += $c->{windows}; $answers += $c->{answers}; $claims += $c->{claims}; $kongs += $c->{kongs}; $robs += $c->{robs}; $discards += $c->{discards};
	$per_seat{$_} += $seat_moves{$_} || 0 for 0 .. 3;
	for my $t (@{ $g->totals }) { $lowest = $t if $t < $lowest; $highest = $t if $t > $highest }
}
my $secs = Time::HiRes::time() - $t0;

is_deeply(\@bad, [], 'no invariant broke, no move was refused') or diag join "\n", @bad[0 .. ($#bad < 20 ? $#bad : 20)];
is(scalar @moves_game, $SOAK, "$SOAK games");
my $hands_total = $by{self} + $by{discard} + $by{rob} + $by{exhausted};
is($hands_total, 16 * $SOAK, 'sixteen hands a game');
ok($by{self} && $by{discard} && $by{exhausted}, 'self-drawn wins, discard wins and exhausted hands all occurred');

diag sprintf 'games %d in %.1fs (%.2fs a game)', $SOAK, $secs, $secs / $SOAK;
diag sprintf 'moves a game: median %d, p95 %d, max %d, mean %.0f', pct(0.5, @moves_game), pct(0.95, @moves_game), pct(1, @moves_game), mean(@moves_game);
diag sprintf 'moves a hand: median %.1f, p95 %.1f, max %.1f', pct(0.5, @moves_hand), pct(0.95, @moves_hand), pct(1, @moves_hand);
diag sprintf 'of which a hand: discards %.1f, answers %.1f (claims %.1f), kongs %.2f, robs %.3f', map { $_ / $hands_total } $discards, $answers, $claims, $kongs, $robs;
diag sprintf 'windows a hand %.1f; answers a window %.2f', $windows / $hands_total, $windows ? $answers / $windows : 0;
diag sprintf 'hands ending by: self %d (%.0f%%), discard %d (%.0f%%), rob %d, exhausted %d (%.0f%%)',
	$by{self}, 100 * $by{self} / $hands_total, $by{discard}, 100 * $by{discard} / $hands_total, $by{rob}, $by{exhausted}, 100 * $by{exhausted} / $hands_total;
diag sprintf 'moves a game per seat (seat 3 dull in one game of four): %s', join(', ', map { sprintf '%d', $per_seat{$_} / $SOAK } 0 .. 3);
diag sprintf 'totals seen: lowest %d, highest %d', $lowest, $highest;

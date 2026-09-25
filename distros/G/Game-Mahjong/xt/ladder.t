#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Mahjong;
use Play;

# THE LADDER. One seat at the higher rung against three at the lower, the
# measured seat rotating, GAMES a pairing (default 100). The senior
# instrument is the measured seat's mean points a game (zero-sum, so a
# seat that is no better averages zero); the junior is games won. The
# ablation prices each rung-three idea against the full rung. Printed, and
# the marks are 12's.

my $GAMES = $ENV{GAMES} || 100;

sub tournament {
	my ($high, $low, $tag, %off) = @_;
	my ($points, $wins, $games) = (0, 0, 0);
	for my $n (1 .. $GAMES) {
		my $seat = $n % 4;
		my %bots = map { $_ => Game::Mahjong::Bot->new(level => ($_ == $seat ? $high : $low), seed => "$tag-$n") } 0 .. 3;
		local %Game::Mahjong::Search::OFF = %off;
		my ($g) = Play::play_game(seed => "$tag-$n", chooser => { map { my $s = $_; $s => sub { my ($rules, $st) = @_; $bots{$s}->choose($rules, $st) } } 0 .. 3 });
		$points += $g->totals->[$seat];
		$wins++ if defined $g->winner && $g->winner == $seat;
		$games++;
	}
	return ($points / $games, $wins);
}

plan tests => 4;

my ($p21, $w21) = tournament(2, 1, 'two-v-one');
diag sprintf 'rung 2 v three rung 1s: %.1f points a game, %d of %d games won', $p21, $w21, $GAMES;
cmp_ok($p21, '>', 0, 'rung 2 scores above zero against rung 1s');

my ($p32, $w32) = tournament(3, 2, 'three-v-two');
diag sprintf 'rung 3 v three rung 2s: %.1f points a game, %d of %d games won', $p32, $w32, $GAMES;
cmp_ok($p32, '>', 0, 'rung 3 scores above zero against rung 2s');

my ($p31, $w31) = tournament(3, 1, 'three-v-one');
diag sprintf 'rung 3 v three rung 1s: %.1f points a game, %d of %d games won', $p31, $w31, $GAMES;
cmp_ok($p31, '>', 0, 'rung 3 scores above zero against rung 1s');

subtest 'the ablation of rung three' => sub {
	for my $idea (qw(defence planning)) {
		my ($p, $w) = tournament(3, 3, "off-$idea", $idea => 1);
		diag sprintf 'rung 3 without %s v three full rung 3s: %.1f points a game, %d won', $idea, $p, $w;
		pass("$idea priced");
	}
};

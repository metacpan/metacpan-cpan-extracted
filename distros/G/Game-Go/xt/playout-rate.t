#!perl

# PLAYOUTS PER SECOND, PER SIZE. Measured and recorded, with no threshold.
#
# This is what fills in Game::Go::Bot's level table, and it is a release test
# because it is a measurement rather than an assertion: a threshold here would
# be a statement about the machine it last ran on.
#
# What is NOT machine-dependent is that the levels are playout COUNTS. A slower
# machine plays the same moves more slowly rather than playing different ones,
# which is the whole reason the budget is not in seconds.

use 5.010;
use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);

unless ($ENV{RELEASE_TESTING} || $ENV{GO_MEASURE}) {
	plan skip_all => 'a measurement, not an assertion: set RELEASE_TESTING or GO_MEASURE';
}

use Game::Go;
use Game::Go::Bot;
use Game::Go::Engine;

my $B = Game::Go::BLACK;

diag('');
diag(sprintf '%-7s %12s %14s', 'size', 'playouts/sec', 'avg moves');

my %rate;
for my $size (Game::Go->sizes) {
	my $b = Game::Go::Engine->new(size => $size, history => 0);
	my $n = $size >= 19 ? 60 : 300;

	my ($t0, $moves) = (time, 0);
	for my $seed (1 .. $n) {
		my $r = $b->playout(colour => $B, seed => $seed);
		$moves += $r->{moves};
	}
	my $dt = time - $t0;

	$rate{$size} = $n / ($dt || 1e-9);
	diag(sprintf '%-7s %12.0f %14.0f', "${size}x$size", $rate{$size}, $moves / $n);

	cmp_ok($rate{$size}, '>', 0, "${size}x$size: playouts happen");
}

diag('');
diag(sprintf '%-7s %6s %10s %12s', 'size', 'level', 'playouts', 'ms/move');

for my $size (Game::Go->sizes) {
	for my $level (1 .. 5) {
		# BEST OF THREE, because one sample is not a measurement. The first
		# draft of this file took one, and reported 19x19 level 5 at 727 ms
		# where three trials put it at 244: a single run had caught the machine
		# doing something else, and the number went into a plan before anybody
		# checked it.
		my $best;
		for my $trial (1 .. 3) {
			my $bot = Game::Go::Bot->new(level => $level, seed => "measure$trial");
			my $g = Game::Go->new(size => $size);
			my $t0 = time;
			$bot->choose($g, $B);
			my $ms = (time - $t0) * 1000;
			$best = $ms if !defined $best || $ms < $best;
		}

		diag(sprintf '%-7s %6d %10d %12.1f',
			"${size}x$size", $level,
			Game::Go::Bot->new(level => $level)->budget($size), $best);
	}
}

diag('');
diag('The top rung on each board is built to land near a quarter of a second.');
diag('Gate mark 7 is what turns these numbers into a decision about go19.');

pass('measured and recorded');
done_testing();

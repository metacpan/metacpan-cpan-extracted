#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Digest::SHA ();

use Game::Floppy;
use Game::Floppy::Test::Fly;

# THE GAP FALLS FROM THE SEED: tube k's gap_top is (height - 100) minus
# unpack('N', sha256($seed . "floppy:tube:$k")) % (height - 100), 0.08's
# int(rand($height - 100)) with the seed in place of rand. So the same seed
# and the same flaps are the same game twice, and a test can compute a gap by
# hand.

sub expected_gap_top {
	my ($seed, $k, $height) = @_;
	my $range = $height - 100;
	return $range - unpack('N', substr(Digest::SHA::sha256($seed . "floppy:tube:$k"), 0, 4)) % $range;
}

subtest 'the first two gaps, by hand' => sub {
	for my $seed (qw/ one two three /) {
		my $game = Game::Floppy->new(seed => $seed);
		my $fly = Game::Floppy::Test::Fly->every(10);
		for (1 .. 200) { $game->flap if $fly->($game); $game->tick }
		my $tubes = $game->tubes;
		is(scalar @$tubes, 2, "seed '$seed': two tubes at tick 200");
		is($tubes->[0]{gap_top}, expected_gap_top($seed, 0, 400), 'the first gap is where the k=0 hash says');
		is($tubes->[1]{gap_top}, expected_gap_top($seed, 1, 400), 'the second where the k=1 hash says');
		isnt($tubes->[1]{gap_top}, expected_gap_top($seed, 0, 400), 'and not where k=0 would put it')
			if expected_gap_top($seed, 0, 400) != expected_gap_top($seed, 1, 400);
		is($tubes->[0]{gap_bottom} - $tubes->[0]{gap_top}, 140, 'the gap is 140');
	}
};

subtest 'gap_top is between 1 and 300 over fifty tubes' => sub {
	my ($low, $high) = (999, -999);
	for my $i (1 .. 50) {
		my $game = Game::Floppy->new(seed => "range$i");
		Game::Floppy::Test::Fly->advance($game, 100);
		my $top = $game->tubes->[0]{gap_top};
		$low = $top if $top < $low;
		$high = $top if $top > $high;
	}
	cmp_ok($low, '>=', 1, "the lowest seen is $low");
	cmp_ok($high, '<=', 300, "the highest seen is $high");
	cmp_ok($high - $low, '>', 100, 'and they spread');
};

subtest 'every tube is where the timeline says, every tick' => sub {
	my $game = Game::Floppy->new(seed => 'timeline');
	my $fly = Game::Floppy::Test::Fly->every(10);
	my $checked = 0;
	for (1 .. 1000) {
		$game->flap if $fly->($game);
		my $step = $game->tick;
		last if $step->{died};
		for my $tube (@{ $game->tubes }) {
			my $spawn = 100 * ($tube->{k} + 1);
			fail("tube $tube->{k} at x $tube->{x} on tick " . $game->ticks)
				unless $tube->{x} == 516 - 3 * ($game->ticks - $spawn);
			$checked++;
		}
	}
	cmp_ok($checked, '>', 100, "$checked tube positions agreed with the timeline");
};

subtest 'the same seed and the same flaps are the same game twice' => sub {
	my @runs;
	for (1 .. 2) {
		my $game = Game::Floppy->new(seed => 'twice');
		my $fly = Game::Floppy::Test::Fly->every(10);
		my @tubes;
		for (1 .. 500) {
			$game->flap if $fly->($game);
			my $step = $game->tick;
			push @tubes, [ map { "$_->{k}:$_->{x}:$_->{gap_top}" } @{ $game->tubes } ];
			last if $step->{died};
		}
		push @runs, { tubes => \@tubes, score => $game->score, ticks => $game->ticks,
			cause => $game->result ? $game->result->cause : 'running' };
	}
	is_deeply($runs[0], $runs[1], 'identical tubes every tick and the same ending');
};

subtest 'a taller field has a wider range' => sub {
	my $game = Game::Floppy->new(seed => 'tall', height => 600);
	Game::Floppy::Test::Fly->advance($game, 100);
	is($game->tubes->[0]{gap_top}, expected_gap_top('tall', 0, 600), 'the range is height - 100');
};

done_testing();

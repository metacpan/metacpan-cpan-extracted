#!perl

# DOES THE ENGINE GIVE BACK WHAT IT TAKES.
#
# The board is a C allocation behind a Perl object, and the search allocates a
# position PER PLAYOUT. At the bot's top rung that is three thousand boards for
# one move, so a leak of a few hundred bytes a board is a leak of megabytes a
# move, and a correspondence game on a server would find it long before a test
# did.
#
# go_abi.h documents ownership per table entry precisely because this is the
# class of bug XS adds and nothing else in the suite would notice: every test
# passes, every number is right, and the process grows.
#
# WHAT THIS MEASURES IS RESIDENT SET SIZE, WHICH IS NOT MALLOC. A process that
# has freed everything may still hold the pages, and one that has leaked may not
# have grown yet. So the assertion is deliberately loose: after a warm-up, a
# further N iterations must not grow the process by more than a per-iteration
# budget far smaller than the allocation being made and freed. A real leak of a
# whole board crosses it by orders of magnitude; page-level noise does not come
# close.

use 5.010;
use strict;
use warnings;
use Test::More;

plan skip_all => 'RELEASE_TESTING' unless $ENV{RELEASE_TESTING};

use Game::Go;
use Game::Go::Bot;
use Game::Go::Rules;

# ps is not portable and /proc is not on darwin. Getting this wrong quietly is
# worse than not running, so an unknown platform SKIPS ALL with a reason rather
# than measuring nothing and passing.
sub rss_kb {
	if (open my $fh, '<', "/proc/$$/statm") {
		my $line = <$fh>;
		close $fh;
		my (undef, $resident) = split /\s+/, $line;
		# statm is in pages.
		my $page = eval { require POSIX; POSIX::sysconf(POSIX::_SC_PAGESIZE()) } || 4096;
		return int($resident * $page / 1024);
	}

	my $out = `ps -o rss= -p $$ 2>/dev/null`;
	return undef unless defined $out && $out =~ /([0-9]+)/;
	return $1 + 0;
}

plan skip_all => 'cannot read this process RSS on this platform'
	unless defined rss_kb();

my $N = $ENV{GO_LEAK_ITERATIONS} || 20_000;

# One iteration's worth of allocation, so the budget below can be stated against
# something real rather than against a round number.
my $BOARD_BYTES = 19 * 19 * 40;    # generous: the padded arrays for a 19x19

subtest 'building and dropping boards' => sub {
	# A board is allocated, played on and dropped. If new/free are not paired
	# this is where it shows first, because it is the cheapest loop.
	my $warm = 2_000;
	$_ = Game::Go->new(size => 9, seed => "leak-$_") for 1 .. $warm;

	my $before = rss_kb();
	for my $i (1 .. $N) {
		my $game = Game::Go->new(size => 9, seed => "leak-$i");
		$game->play($game->turn, $game->point(4, 4));
	}
	my $after = rss_kb();

	my $grew = $after - $before;
	my $budget = int($N * 64 / 1024) + 512;    # 64 bytes an iteration, plus slack
	diag("$N boards: RSS ${before}k -> ${after}k (${grew}k, budget ${budget}k)");
	cmp_ok($grew, '<=', $budget, "$N boards did not grow the process");
	done_testing();
};

subtest 'cloning, which copies the C allocation' => sub {
	# clone is where an ownership mistake is easiest to make: the copy owns its
	# own board and the original must still own its own.
	my $game = Game::Go->new(size => 13, seed => 'leak-clone');
	$game->play($game->turn, $game->point(3, 3)) for 1 .. 1;

	$_ = $game->clone for 1 .. 2_000;

	my $before = rss_kb();
	for my $i (1 .. $N) {
		my $copy = $game->clone;
		$copy->play($copy->turn, $copy->point(9, 9));
	}
	my $after = rss_kb();

	my $grew = $after - $before;
	my $budget = int($N * 64 / 1024) + 512;
	diag("$N clones: RSS ${before}k -> ${after}k (${grew}k, budget ${budget}k)");
	cmp_ok($grew, '<=', $budget, "$N clones did not grow the process");
	done_testing();
};

subtest 'the search, which allocates a position per playout' => sub {
	# THE ONE THAT MATTERS. The bot's top rung is three thousand playouts for
	# one move, so a per-playout leak is megabytes a move.
	my $game = Game::Go->new(size => 9, seed => 'leak-search');
	my $bot = Game::Go::Bot->new(level => 1, seed => 'leak');

	$bot->choose($game, $game->turn) for 1 .. 20;

	# THE ROOT SET IS NOT OPTIONAL. `allowed` defaults to the empty list, and a
	# search with no roots runs no playouts at all and allocates nothing: the
	# first version of this subtest passed because it was measuring a search
	# that never happened.
	my $colour = $game->turn;
	my @allowed = map { $_->kind eq 'pass' ? -1 : $_->point } @{ $game->legal($colour) };
	cmp_ok(scalar @allowed, '>', 1, scalar(@allowed) . ' root moves to search');

	my $moves = $ENV{GO_LEAK_MOVES} || 400;
	my $before = rss_kb();
	my $played = 0;
	for my $i (1 .. $moves) {
		my $out = $game->search_from(
			colour   => $colour,
			allowed  => \@allowed,
			playouts => 200,
			seed     => $i,
		);
		$played += $out->{playouts};
	}
	my $after = rss_kb();

	cmp_ok($played, '>=', $moves * 100, "$played playouts actually ran");

	my $grew = $after - $before;
	# 200 playouts a call, each allocating and freeing a board.
	my $budget = 1024;
	diag("$moves searches of 200 playouts: RSS ${before}k -> ${after}k "
		. "(${grew}k, budget ${budget}k)");
	cmp_ok($grew, '<=', $budget, 'the search gave its positions back');
	done_testing();
};

done_testing();
